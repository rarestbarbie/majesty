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
    FactoryTableEntry,
    FactoryTableRow,
    FactoryDetailsTab,
    LegalEntityFilterLabel,
    LegalEntityFilter,
    InventoryBreakdown,
    InventoryCharts,
    OwnershipBreakdown,
    ProductionReport,
    ScreenType,
    TooltipType,
} from '../exports.js';

export class ProductionOverview extends ScreenContent {
    private readonly filters: FilterList<LegalEntityFilter, string>[];
    private readonly factories: StaticList<FactoryTableRow, GameID>;

    private readonly inventoryCharts: InventoryCharts;
    private readonly inventory: InventoryBreakdown;
    private readonly ownership: OwnershipBreakdown;

    private dom?: {
        readonly index: FilterTabs;
        readonly panel: HTMLDivElement;
        readonly title: HTMLElement;
        readonly titleName: HTMLHeadingElement;
        readonly stats: HTMLDivElement;
        readonly nav: HTMLElement;
    };

    static readonly screen: ScreenType = ScreenType.Production;
    static readonly tooltipCashFlowItem: TooltipType = TooltipType.FactoryCashFlowItem;
    static readonly tooltipBudgetItem: TooltipType = TooltipType.FactoryBudgetItem;
    static readonly tooltipExplainPrice: TooltipType = TooltipType.FactoryExplainPrice;
    static readonly tooltipNeeds: TooltipType = TooltipType.FactoryNeeds;
    static readonly tooltipResourceIO: TooltipType = TooltipType.FactoryResourceIO;
    static readonly tooltipStockpile: TooltipType = TooltipType.FactoryStockpile;

    constructor() {
        super();

        this.filters = [
            new FilterList<LegalEntityFilter, string>('🌐'),
        ];

        this.factories = new StaticList<FactoryTableRow, GameID>(document.createElement('div'));
        this.factories.table('Factories', FactoryTableRow.columns);

        this.inventoryCharts = new InventoryCharts(ProductionOverview);
        this.inventory = new InventoryBreakdown();
        this.ownership = new OwnershipBreakdown(
            TooltipType.FactoryOwnershipCountry,
            TooltipType.FactoryOwnershipCulture,
            TooltipType.FactoryOwnershipGender
        );
    }

    public override async open(parameters: URLSearchParams): Promise<void> {
        const factory: string | null = parameters.get('id');
        const state: ProductionReport = await Swift.openProduction(
            {
                subject: factory ? parseInt(factory) as GameID ?? undefined : undefined,
                details: parameters.get('details') as FactoryDetailsTab ?? undefined,
                detailsTier: parameters.get('detailsTier') ?? undefined,
                filter: parameters.get('filter') ?? undefined
            }
        );

        this.inventory.clear();

        if (this.dom === undefined) {
            this.dom = {
                index: new FilterTabs(this.filters),
                panel: document.createElement('div'),
                title: document.createElement('header'),
                titleName: document.createElement('h3'),
                stats: document.createElement('div'),
                nav: document.createElement('nav'),
            }

            this.dom.title.appendChild(this.dom.titleName);
            this.dom.title.appendChild(this.dom.nav);

            const upper: HTMLDivElement = document.createElement('div');
            upper.classList.add('upper');
            upper.appendChild(this.dom.title);
            upper.appendChild(this.dom.stats);

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
            case FactoryDetailsTab.Ownership: link.textContent = 'Investors'; break;
            }

            if (tab == state.factory?.open.type) {
                link.classList.add('selected');
            }

            this.dom.nav.appendChild(link);
        }

        switch (state.factory?.open.type) {
        case FactoryDetailsTab.Inventory:
            this.dom.stats.setAttribute('data-subscreen', 'Inventory');
            this.dom.stats.appendChild(this.inventory.node);
            this.dom.stats.appendChild(this.inventoryCharts.node);
            break;

        case FactoryDetailsTab.Ownership:
            this.dom.stats.setAttribute('data-subscreen', 'Ownership');
            this.dom.stats.appendChild(this.ownership.node);
            break;
        }

        this.dom.index.tabs[state.filterlist].checked = true;
        this.update(state);
    }

    public override attach(root: HTMLElement): void {
        if (this.dom !== undefined) {
            root.appendChild(this.dom.index.node);
            root.appendChild(this.dom.panel);
        }
    }
    public override detach(): void {
        if (this.dom !== undefined) {
            this.dom.index.node.remove();
            this.dom.panel.remove();
            this.dom = undefined;
        } else {
            throw new Error('ProductionOverview not attached');
        }
    }

    public update(state: ProductionReport): void {
        if (this.dom === undefined) {
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
                (label: LegalEntityFilterLabel) => new LegalEntityFilter(
                    label,
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

        let id: GameID = state.factory.id;

        switch (state.factory.open.type) {
        case FactoryDetailsTab.Inventory:
            this.inventory.update(id, state.factory.open, ProductionOverview);
            this.inventoryCharts.update(id, state.factory.open);
            break;

        case FactoryDetailsTab.Ownership:
            this.ownership.update(id, state.factory.open);
            break;
        }
    }
}
