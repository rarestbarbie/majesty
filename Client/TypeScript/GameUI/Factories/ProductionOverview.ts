import {
    FilterTabs,
    FilterList,
    StaticList,
    UpdateText
} from '../../DOM/exports.js';
import { GameID } from '../../GameEngine/GameID.js';
import { ScreenContent } from '../Application/ScreenContent.js';
import { Swift } from '../../Swift.js';
import {
    ConsumptionBreakdown,
    FactoryTableEntry,
    FactoryTableRow,
    FactoryDetailsTab,
    LegalEntityFilterLabel,
    MarketFilter,
    OwnershipBreakdown,
    ProductionReport,
    ResourceNeed,
    ResourceNeedRow,
    ResourceSale,
    ResourceSaleBox,
    ScreenType,
    TooltipType,
} from '../exports.js';

export class ProductionOverview extends ScreenContent {
    private readonly filters: FilterList<MarketFilter, string>[];
    private readonly factories: StaticList<FactoryTableRow, GameID>;
    private readonly sales: StaticList<ResourceSaleBox, string>;

    private readonly consumption: ConsumptionBreakdown;
    private readonly ownership: OwnershipBreakdown;

    private dom?: {
        readonly index: FilterTabs;
        readonly panel: HTMLDivElement;
        readonly title: HTMLElement;
        readonly titleName: HTMLSpanElement;
        readonly stats: HTMLDivElement;
        readonly nav: HTMLElement;
    };

    static readonly screen: ScreenType = ScreenType.Production;
    static readonly tooltipCashFlowItem: TooltipType = TooltipType.FactoryCashFlowItem;
    static readonly tooltipBudgetItem: TooltipType = TooltipType.FactoryBudgetItem;
    static readonly tooltipExplainPrice: TooltipType = TooltipType.FactoryExplainPrice;
    static readonly tooltipResourceIO: TooltipType = TooltipType.FactoryResourceIO;
    static readonly tooltipStockpile: TooltipType = TooltipType.FactoryStockpile;

    constructor() {
        super();

        this.filters = [
            new FilterList<MarketFilter, string>('🌐'),
        ];

        this.factories = new StaticList<FactoryTableRow, GameID>(document.createElement('div'));
        this.factories.table('Factories', FactoryTableRow.columns);

        this.sales = new StaticList<ResourceSaleBox, string>(document.createElement('div'));

        this.consumption = new ConsumptionBreakdown(ProductionOverview);
        this.ownership = new OwnershipBreakdown(
            TooltipType.FactoryOwnershipCountry,
            TooltipType.FactoryOwnershipCulture,
            TooltipType.FactoryOwnershipSecurities,
        );
    }

    public override attach(root: HTMLElement | null, parameters: URLSearchParams): void {
        const factory: string | null = parameters.get('id');
        const state: ProductionReport = Swift.openProduction(
            {
                subject: factory ? parseInt(factory) as GameID ?? undefined : undefined,
                details: parameters.get('details') as FactoryDetailsTab ?? undefined,
                detailsTier: parameters.get('detailsTier') ?? undefined,
                filter: parameters.get('filter') ?? undefined
            }
        );

        this.sales.clear();
        this.sales.node.classList.add('sales');

        if (!this.dom) {
            this.dom = {
                index: new FilterTabs(this.filters),
                panel: document.createElement('div'),
                title: document.createElement('header'),
                titleName: document.createElement('span'),
                stats: document.createElement('div'),
                nav: document.createElement('nav'),
            }

            this.dom.title.appendChild(this.dom.titleName);

            const upper: HTMLDivElement = document.createElement('div');
            upper.appendChild(this.dom.title);
            upper.appendChild(this.dom.stats);
            upper.appendChild(this.dom.nav);

            this.dom.panel.appendChild(upper);
            this.dom.panel.appendChild(this.factories.node);
            this.dom.panel.classList.add('panel');

            this.dom.stats.classList.add('stats');
        } else {
            this.dom.stats.replaceChildren();
            this.dom.nav.replaceChildren();
        }

        for (const tab of [FactoryDetailsTab.Inventory, FactoryDetailsTab.Ownership]) {
            const link: HTMLAnchorElement = document.createElement('a');
            link.href = `#screen=${ScreenType.Production}&details=${tab}`;

            switch (tab) {
            case FactoryDetailsTab.Inventory: link.textContent = 'Consumption'; break;
            case FactoryDetailsTab.Ownership: link.textContent = 'Capital Structure'; break;
            }

            if (tab == state.factory?.open.type) {
                link.classList.add('selected');
            }

            this.dom.nav.appendChild(link);
        }

        switch (state.factory?.open.type) {
        case FactoryDetailsTab.Inventory:
            this.dom.stats.setAttribute('data-subscreen', 'Inventory');
            this.dom.stats.appendChild(this.consumption.node);
            this.dom.stats.appendChild(this.sales.node);
            break;

        case FactoryDetailsTab.Ownership:
            this.dom.stats.setAttribute('data-subscreen', 'Ownership');
            this.dom.stats.appendChild(this.ownership.node);
            break;
        }

        if (root) {
            root.appendChild(this.dom.index.node);
            root.appendChild(this.dom.panel);
        }

        this.dom.index.tabs[state.filterlist ?? 0].checked = true;
        this.update(state);
    }

    public override detach(): void {
        if (!this.dom) {
            throw new Error('ProductionOverview not attached');
        }

        this.dom.index.node.remove();
        this.dom.panel.remove();
        this.dom = undefined;
    }

    public update(state: ProductionReport): void {
        if (!this.dom || state.factories.length == 0) {
            return;
        }

        this.factories.update(
            state.factories,
            (factory: FactoryTableEntry) => new FactoryTableRow(factory),
            (factory: FactoryTableEntry, row: FactoryTableRow) => row.update(factory),
            state.factory?.id
        );

        for (let i: number = 0; i < this.dom.index.tabs.length; i++) {
            this.filters[i].update(
                state.filterlists[i],
                (label: LegalEntityFilterLabel) => new MarketFilter(
                    {
                        id: label.id,
                        name: label.name,
                        icon: '',
                    },
                    ScreenType.Production
                ),
                () => {},
                state.filter
            );
        }

        if (state.factory === undefined) {
            return;
        }

        UpdateText(this.dom.titleName, state.factory.type ?? '');

        switch (state.factory.open.type) {
        case FactoryDetailsTab.Inventory:
            let id: GameID = state.factory.id;

            this.consumption.update(id, state.factory.open, ProductionOverview);
            this.sales.update(
                state.factory.open.sales,
                (sale: ResourceSale) => new ResourceSaleBox(
                    sale,
                    id,
                    ProductionOverview.tooltipResourceIO,
                    ProductionOverview.tooltipExplainPrice,
                ),
                (sale: ResourceSale, box: ResourceSaleBox) => box.update(sale),
            );

            break;

        case FactoryDetailsTab.Ownership:
            this.ownership.update(state.factory.id, state.factory.open);
            break;
        }
    }
}
