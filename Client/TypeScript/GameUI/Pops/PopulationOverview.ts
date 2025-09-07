import { StaticList, UpdateText } from '../../DOM/exports.js';
import { GameID } from '../../GameEngine/GameID.js';
import { ScreenContent } from '../ScreenContent.js';
import { Swift } from '../../Swift.js';
import {
    PieChart,
    PopulationReport,
    PopTableEntry,
    PopTableRow,
    ResourceNeed,
    ResourceNeedRow,
    ResourceSale,
    ResourceSaleBox,
    Resource,
    ScreenType,
    TooltipType,
    PopIcon,
} from '../exports.js';

export class PopulationOverview extends ScreenContent {
    private needs: StaticList<ResourceNeedRow, Resource>;
    private sales: StaticList<ResourceSaleBox, Resource>;
    private readonly charts: {
        readonly spending: PieChart<string>;
    };

    private pops: StaticList<PopTableRow, GameID>;
    private dom?: {
        readonly index: HTMLUListElement;
        readonly panel: HTMLDivElement;
        readonly title: HTMLElement;
        readonly titleIcon: PopIcon;
        readonly titleName: HTMLSpanElement;
        readonly stats: HTMLDivElement;
        readonly nav: HTMLElement;
    };

    constructor() {
        super();

        this.pops = new StaticList<PopTableRow, GameID>(document.createElement('div'));
        this.pops.table('Pops', PopTableRow.columns);

        this.needs = new StaticList<ResourceNeedRow, Resource>(document.createElement('div'));
        this.sales = new StaticList<ResourceSaleBox, Resource>(document.createElement('div'));
        this.charts = {
            spending: new PieChart<string>(TooltipType.PopStatementItem),
        };
    }

    public override attach(root: HTMLElement | null, parameters: URLSearchParams): void {
        let subject: string | null = parameters.get('id');
        let state: PopulationReport = Swift.openPopulation(
            subject ? parseInt(subject) as GameID : null,
        );

        // We need to empty the upper content, as we will need to replace the IDs.
        this.needs.table('Needs', ResourceNeedRow.columns);
        this.sales.clear();
        this.sales.node.classList.add('sales');

        if (!this.dom) {
            this.dom = {
                index: document.createElement('ul'),
                panel: document.createElement('div'),
                title: document.createElement('header'),
                titleIcon: new PopIcon(),
                titleName: document.createElement('span'),
                stats: document.createElement('div'),
                nav: document.createElement('nav'),
            }

            this.dom.title.appendChild(this.dom.titleIcon.node);
            this.dom.title.appendChild(this.dom.titleName);

            const upper: HTMLDivElement = document.createElement('div');
            upper.appendChild(this.dom.title);
            upper.appendChild(this.dom.stats);
            upper.appendChild(this.dom.nav);

            this.dom.panel.appendChild(upper);
            this.dom.panel.appendChild(this.pops.node);
            this.dom.panel.classList.add('panel');

            const right: HTMLDivElement = document.createElement('div');
            right.appendChild(this.sales.node);
            right.appendChild(this.charts.spending.node);

            this.dom.stats.setAttribute('data-subscreen', 'Inventory');
            this.dom.stats.appendChild(this.needs.node);
            this.dom.stats.appendChild(right);
            this.dom.stats.classList.add('stats');
        }
        if (root) {
            root.appendChild(this.dom.index);
            root.appendChild(this.dom.panel);
        }

        this.update(state);
    }

    public override detach(): void {
        if (!this.dom) {
            throw new Error('PopulationOverview not attached');
        }

        this.dom.index.remove();
        this.dom.panel.remove();
        this.dom = undefined;
    }

    public update(state: PopulationReport): void {
        if (!this.dom || state.pops.length == 0) {
            return;
        }

        this.pops.update(
            state.pops,
            (pop: PopTableEntry) => new PopTableRow(pop),
            (pop: PopTableEntry, row: PopTableRow) => row.update(pop),
            state.pop?.id
        );

        if (state.pop) {
            const id: GameID = state.pop.id;

            UpdateText(this.dom.titleName, state.pop.type_singular ?? '');
            this.dom.titleIcon.set({ id: state.pop.id, type: state.pop.type ?? '' });

            this.needs.update(
                state.pop.needs,
                (need: ResourceNeed) => new ResourceNeedRow(
                    need,
                    id,
                    TooltipType.PopDemand,
                    TooltipType.PopStockpile,
                    TooltipType.PopExplainPrice,
                ),
                (need: ResourceNeed, row: ResourceNeedRow) => row.update(need),
            );

            this.sales.update(
                state.pop.sales,
                (sale: ResourceSale) => new ResourceSaleBox(
                    sale,
                    id,
                    TooltipType.PopSupply,
                    TooltipType.PopExplainPrice,
                ),
                (sale: ResourceSale, box: ResourceSaleBox) => box.update(sale),
            );

            this.charts.spending.update([id], state.pop.spending ?? []);
        } else {
            UpdateText(this.dom.titleName, '');
            this.dom.titleIcon.set(null);
        }
    }
}
