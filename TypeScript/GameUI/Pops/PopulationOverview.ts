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
    LegalEntityFilterLabel,
    MarketFilter,
    PopulationReport,
    PopDetailsTab,
    PopTableEntry,
    PopTableRow,
    ResourceSale,
    ResourceSaleBox,
    Resource,
    ScreenType,
    TooltipType,
    PopIcon,
    ConsumptionBreakdown,
    OwnershipBreakdown,
} from '../exports.js';

export class PopulationOverview extends ScreenContent {
    private filters: FilterList<MarketFilter, string>[];
    private sales: StaticList<ResourceSaleBox, string>;

    private readonly consumption: ConsumptionBreakdown;
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

        this.filters = [
            new FilterList<MarketFilter, string>('🌐'),
        ];

        this.pops = new Table<PopTableRow, GameID>('Pops');
        this.sales = new StaticList<ResourceSaleBox, string>(document.createElement('div'));

        this.consumption = new ConsumptionBreakdown(PopulationOverview);
        this.ownership = new OwnershipBreakdown(
            TooltipType.PopOwnershipCountry,
            TooltipType.PopOwnershipCulture,
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
        this.sales.clear();
        this.sales.node.classList.add('sales');

        if (this.dom === undefined) {
            this.dom = {
                index: new FilterTabs(this.filters),
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

            const upper: HTMLDivElement = document.createElement('div');
            upper.classList.add('upper');
            upper.appendChild(this.dom.title);
            upper.appendChild(this.dom.stats);

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
            this.dom.stats.appendChild(this.consumption.node);
            this.dom.stats.appendChild(this.sales.node);
            break;

        case PopDetailsTab.Ownership:
            this.dom.stats.setAttribute('data-subscreen', 'Ownership');
            this.dom.stats.appendChild(this.ownership.node);
            break;
        }

        this.dom.index.tabs[state.filterlist ?? 0].checked = true;
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
            this.filters[i].update(
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

        switch (state.pop.open.type) {
        case PopDetailsTab.Inventory:
            const id: GameID = state.pop.id;

            this.consumption.update(id, state.pop.open, PopulationOverview);
            this.sales.update(
                state.pop.open.sales,
                (sale: ResourceSale) => new ResourceSaleBox(sale, id, PopulationOverview),
                (sale: ResourceSale, box: ResourceSaleBox) => box.update(sale, id),
            );
            break;

        case PopDetailsTab.Ownership:
            this.ownership.update(state.pop.id, state.pop.open);
            break;
        }
    }
}
