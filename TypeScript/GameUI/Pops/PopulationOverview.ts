import {
    FilterList,
    FilterTabs,
    StaticList,
    Table,
    UpdateText
} from '../../DOM/exports.js';
import { GameID } from '../../GameEngine/GameID.js';
import { ScreenContent } from '../Application/ScreenContent.js';
import { Swift } from '../../Swift.js';
import {
    GenderFilter,
    InventoryBreakdown,
    InventoryCharts,
    LegalEntityFilterLabel,
    MarketFilter,
    OwnershipBreakdown,
    PopulationReport,
    PopDetailsTab,
    PopIcon,
    PopTableEntry,
    PopTableRow,
    ScreenType,
    TooltipType,
} from '../exports.js';

export class PopulationOverview extends ScreenContent {
    private regions: FilterList<MarketFilter, string>[];
    private sexes: StaticList<GenderFilter, string>;

    private readonly inventoryCharts: InventoryCharts;
    private readonly inventory: InventoryBreakdown;
    private readonly ownership: OwnershipBreakdown;

    private pops: Table<PopTableRow, GameID>;
    private dom?: {
        readonly index: FilterTabs;
        readonly panel: HTMLDivElement;
        readonly title: HTMLElement;
        readonly titleIcon: PopIcon;
        readonly titleName: HTMLHeadingElement;
        readonly stats: HTMLDivElement;
        readonly nav: HTMLElement;
    };

    static readonly screen: ScreenType = ScreenType.Population;
    static readonly tooltipCashFlowItem: TooltipType = TooltipType.PopCashFlowItem;
    static readonly tooltipBudgetItem: TooltipType = TooltipType.PopBudgetItem;
    static readonly tooltipExplainPrice: TooltipType = TooltipType.PopExplainPrice;
    static readonly tooltipNeeds: TooltipType = TooltipType.PopNeeds;
    static readonly tooltipResourceOrigin: TooltipType = TooltipType.PopResourceOrigin;
    static readonly tooltipResourceIO: TooltipType = TooltipType.PopResourceIO;
    static readonly tooltipStockpile: TooltipType = TooltipType.PopStockpile;

    constructor() {
        super();

        this.regions = [
            new FilterList<MarketFilter, string>('🌐'),
        ];
        this.sexes = new StaticList<GenderFilter, string>(document.createElement('ul'));
        this.pops = new Table<PopTableRow, GameID>('Pops');

        this.inventoryCharts = new InventoryCharts(PopulationOverview);
        this.inventory = new InventoryBreakdown();
        this.ownership = new OwnershipBreakdown(
            TooltipType.PopOwnershipCountry,
            TooltipType.PopOwnershipCulture,
            TooltipType.PopOwnershipGender
        );
    }

    public override async open(parameters: URLSearchParams): Promise<void> {
        let subject: string | null = parameters.get('id');
        let state: PopulationReport = await Swift.openPopulation(
            {
                subject: subject ? parseInt(subject) as GameID : undefined,
                details: parameters.get('details') as PopDetailsTab ?? undefined,
                detailsTier: parameters.get('detailsTier') ?? undefined,
                column: parameters.get('column') ?? undefined,
                filter: parameters.get('filter') ?? undefined,
            }
        );

        this.switch(state);
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
            throw new Error('PopulationOverview not attached');
        }
    }

    private switch(state: PopulationReport): void {
        this.inventory.clear();

        if (this.dom === undefined) {
            this.dom = {
                index: new FilterTabs(this.regions),
                panel: document.createElement('div'),
                title: document.createElement('header'),
                titleIcon: new PopIcon(),
                titleName: document.createElement('h3'),
                stats: document.createElement('div'),
                nav: document.createElement('nav'),
            }

            this.dom.title.appendChild(this.dom.titleIcon.occupation);
            this.dom.title.appendChild(this.dom.titleName);
            this.dom.title.appendChild(this.dom.titleIcon.gender);
            this.dom.title.appendChild(this.dom.nav);

            const filters: HTMLDivElement = document.createElement('div');
            filters.classList.add('filters');
            filters.appendChild(this.sexes.node);

            const upper: HTMLDivElement = document.createElement('div');
            upper.classList.add('upper');
            upper.appendChild(this.dom.title);
            upper.appendChild(this.dom.stats);
            upper.appendChild(filters);

            this.dom.panel.appendChild(upper);
            this.dom.panel.appendChild(this.pops.node);
            this.dom.panel.classList.add('panel');

            this.dom.stats.classList.add('stats');
        } else {
            this.dom.stats.replaceChildren();
            this.dom.nav.replaceChildren();
        }

        for (const tab of [PopDetailsTab.Inventory, PopDetailsTab.Ownership]) {
            const link: HTMLAnchorElement = document.createElement('a');
            link.href = `#screen=${ScreenType.Population}&details=${tab}`;

            switch (tab) {
            case PopDetailsTab.Inventory: link.textContent = 'Consumption'; break;
            case PopDetailsTab.Ownership: link.textContent = 'Investors'; break;
            }

            if (tab == state.pop?.open.type) {
                link.classList.add('selected');
            }

            this.dom.nav.appendChild(link);
        }

        switch (state.pop?.open.type) {
        case PopDetailsTab.Inventory:
            this.dom.stats.setAttribute('data-subscreen', 'Inventory');
            this.dom.stats.appendChild(this.inventory.node);
            this.dom.stats.appendChild(this.inventoryCharts.node);
            break;

        case PopDetailsTab.Ownership:
            this.dom.stats.setAttribute('data-subscreen', 'Ownership');
            this.dom.stats.appendChild(this.ownership.node);
            break;
        }

        this.dom.index.tabs[state.filterlist].checked = true;
        this.update(state);
    }

    public update(state: PopulationReport): void {
        if (this.dom === undefined) {
            return;
        }

        this.pops.updateHeader(
            state.columns,
            state.column,
            (target: string) => `screen=${ScreenType.Population}&column=${target}`
        );
        this.pops.update(
            state.pops,
            (pop: PopTableEntry) => new PopTableRow(pop),
            (pop: PopTableEntry, row: PopTableRow) => row.update(pop),
            state.pop?.id
        );

        for (let i: number = 0; i < this.dom.index.tabs.length; i++) {
            this.regions[i].update(
                state.filterlists[i],
                (label: LegalEntityFilterLabel) => new MarketFilter(
                    {
                        id: label.id,
                        name: label.name,
                        icon: '',
                    },
                    ScreenType.Population
                ),
                () => {},
                state.filter
            );
        }
        this.sexes.allocate(
            state.sexes,
            (code: string) => new GenderFilter(code, ScreenType.Population),
            state.sex
        );

        if (state.pop === undefined) {
            return;
        }

        if (state.pop.occupation_singular !== undefined &&
            state.pop.occupation !== undefined &&
            state.pop.gender !== undefined) {
            UpdateText(this.dom.titleName, state.pop.occupation_singular);
            this.dom.titleIcon.set(
                {
                    id: state.pop.id,
                    occupation: state.pop.occupation,
                    gender: state.pop.gender,
                    cis: state.pop.cis ?? false,
                }
            );
        } else {
            UpdateText(this.dom.titleName, '');
            this.dom.titleIcon.set(null);
        }

        const id: GameID = state.pop.id;
        switch (state.pop.open.type) {
        case PopDetailsTab.Inventory:
            this.inventory.update(id, state.pop.open, PopulationOverview);
            this.inventoryCharts.update(id, state.pop.open);
            break;

        case PopDetailsTab.Ownership:
            this.ownership.update(id, state.pop.open);
            break;
        }
    }
}
