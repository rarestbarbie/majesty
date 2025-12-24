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
    BuildingTableEntry,
    BuildingTableRow,
    BuildingDetailsTab,
    LegalEntityFilterLabel,
    MarketFilter,
    OwnershipBreakdown,
    InfrastructureReport,
    InventoryBreakdown,
    InventoryCharts,
    ScreenType,
    TooltipType,
} from '../exports.js';

export class InfrastructureOverview extends ScreenContent {
    private readonly filters: FilterList<MarketFilter, string>[];
    private readonly buildings: StaticList<BuildingTableRow, GameID>;

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

        this.inventoryCharts = new InventoryCharts(InfrastructureOverview);
        this.inventory = new InventoryBreakdown();
        this.ownership = new OwnershipBreakdown(
            TooltipType.BuildingOwnershipCountry,
            TooltipType.BuildingOwnershipCulture,
        );
    }

    public override async open(parameters: URLSearchParams): Promise<void> {
        const building: string | null = parameters.get('id');
        const state: InfrastructureReport = await Swift.openInfrastructure(
            {
                subject: building ? parseInt(building) as GameID ?? undefined : undefined,
                details: parameters.get('details') as BuildingDetailsTab ?? undefined,
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
            case BuildingDetailsTab.Ownership: link.textContent = 'Investors'; break;
            }

            if (tab == state.building?.open.type) {
                link.classList.add('selected');
            }

            this.dom.nav.appendChild(link);
        }

        switch (state.building?.open.type) {
        case BuildingDetailsTab.Inventory:
            this.dom.stats.setAttribute('data-subscreen', 'Inventory');
            this.dom.stats.appendChild(this.inventory.node);
            this.dom.stats.appendChild(this.inventoryCharts.node);
            break;

        case BuildingDetailsTab.Ownership:
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
            throw new Error('InfrastructureOverview not attached');
        }
    }

    public update(state: InfrastructureReport): void {
        if (this.dom === undefined) {
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

        let id: GameID = state.building.id;
        switch (state.building.open.type) {
        case BuildingDetailsTab.Inventory:
            this.inventory.update(id, state.building.open, InfrastructureOverview);
            this.inventoryCharts.update(id, state.building.open);
            break;

        case BuildingDetailsTab.Ownership:
            this.ownership.update(id, state.building.open);
            break;
        }
    }
}
