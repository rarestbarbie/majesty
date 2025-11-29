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
    BuildingTableEntry,
    BuildingTableRow,
    BuildingDetailsTab,
    LegalEntityFilterLabel,
    MarketFilter,
    OwnershipBreakdown,
    InfrastructureReport,
    ResourceNeed,
    ResourceNeedRow,
    ResourceSale,
    ResourceSaleBox,
    ScreenType,
    TooltipType,
} from '../exports.js';

export class InfrastructureOverview extends ScreenContent {
    private readonly filters: FilterList<MarketFilter, string>[];
    private readonly buildings: StaticList<BuildingTableRow, GameID>;
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

    static readonly screen: ScreenType = ScreenType.Infrastructure;
    static readonly tooltipCashFlowItem: TooltipType = TooltipType.BuildingCashFlowItem;
    static readonly tooltipBudgetItem: TooltipType = TooltipType.BuildingBudgetItem;
    static readonly tooltipExplainPrice: TooltipType = TooltipType.BuildingExplainPrice;
    static readonly tooltipNeeds: TooltipType = TooltipType.BuildingNeeds;
    static readonly tooltipResourceIO: TooltipType = TooltipType.BuildingResourceIO;
    static readonly tooltipStockpile: TooltipType = TooltipType.BuildingStockpile;

    constructor() {
        super();

        this.filters = [
            new FilterList<MarketFilter, string>('🌐'),
        ];

        this.buildings = new StaticList<BuildingTableRow, GameID>(document.createElement('div'));
        this.buildings.table('Buildings', BuildingTableRow.columns);

        this.sales = new StaticList<ResourceSaleBox, string>(document.createElement('div'));

        this.consumption = new ConsumptionBreakdown(InfrastructureOverview);
        this.ownership = new OwnershipBreakdown(
            TooltipType.BuildingOwnershipCountry,
            TooltipType.BuildingOwnershipCulture,
        );
    }

    public override attach(root: HTMLElement | null, parameters: URLSearchParams): void {
        const building: string | null = parameters.get('id');
        const state: InfrastructureReport = Swift.openInfrastructure(
            {
                subject: building ? parseInt(building) as GameID ?? undefined : undefined,
                details: parameters.get('details') as BuildingDetailsTab ?? undefined,
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
            upper.classList.add('upper');
            upper.appendChild(this.dom.title);
            upper.appendChild(this.dom.stats);
            upper.appendChild(this.dom.nav);

            this.dom.panel.appendChild(upper);
            this.dom.panel.appendChild(this.buildings.node);
            this.dom.panel.classList.add('panel');

            this.dom.stats.classList.add('stats');
        } else {
            this.dom.stats.replaceChildren();
            this.dom.nav.replaceChildren();
        }

        for (const tab of [BuildingDetailsTab.Inventory, BuildingDetailsTab.Ownership]) {
            const link: HTMLAnchorElement = document.createElement('a');
            link.href = `#screen=${ScreenType.Infrastructure}&details=${tab}`;

            switch (tab) {
            case BuildingDetailsTab.Inventory: link.textContent = 'Consumption'; break;
            case BuildingDetailsTab.Ownership: link.textContent = 'Capital Structure'; break;
            }

            if (tab == state.building?.open.type) {
                link.classList.add('selected');
            }

            this.dom.nav.appendChild(link);
        }

        switch (state.building?.open.type) {
        case BuildingDetailsTab.Inventory:
            this.dom.stats.setAttribute('data-subscreen', 'Inventory');
            this.dom.stats.appendChild(this.consumption.node);
            this.dom.stats.appendChild(this.sales.node);
            break;

        case BuildingDetailsTab.Ownership:
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
            throw new Error('InfrastructureOverview not attached');
        }

        this.dom.index.node.remove();
        this.dom.panel.remove();
        this.dom = undefined;
    }

    public update(state: InfrastructureReport): void {
        if (!this.dom) {
            return;
        }

        this.buildings.update(
            state.buildings,
            (building: BuildingTableEntry) => new BuildingTableRow(building),
            (building: BuildingTableEntry, row: BuildingTableRow) => row.update(building),
            state.building?.id
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
                    ScreenType.Infrastructure
                ),
                () => {},
                state.filter
            );
        }

        if (state.building === undefined) {
            return;
        }

        UpdateText(this.dom.titleName, state.building.type ?? '');

        switch (state.building.open.type) {
        case BuildingDetailsTab.Inventory:
            let id: GameID = state.building.id;

            this.consumption.update(id, state.building.open, InfrastructureOverview);
            this.sales.update(
                state.building.open.sales,
                (sale: ResourceSale) => new ResourceSaleBox(sale, id, InfrastructureOverview),
                (sale: ResourceSale, box: ResourceSaleBox) => box.update(sale, id),
            );

            break;

        case BuildingDetailsTab.Ownership:
            this.ownership.update(state.building.id, state.building.open);
            break;
        }
    }
}
