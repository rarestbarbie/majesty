import {
    StaticList,
    Term,
    TermState
 } from '../DOM/exports.js';
import { GameID } from '../GameEngine/exports.js';
import {
    InventoryBreakdownState,
    PersistentOverviewType,
    PieChart,
    ResourceNeedMeter,
    ResourceNeedMeterState,
    ResourceNeedRow,
    ResourceNeed,
    TooltipType,
} from './exports.js';

export class ConsumptionBreakdown {
    public readonly node: HTMLDivElement;
    public readonly charts: HTMLDivElement;

    private readonly tiers: StaticList<ResourceNeedMeter, string>;
    private readonly needs: StaticList<ResourceNeedRow, string>;
    private readonly terms: StaticList<Term, string>;
    private readonly costs: PieChart<string>;
    private readonly budget: PieChart<string>;

    constructor(type: PersistentOverviewType) {
        this.tiers = new StaticList<ResourceNeedMeter, string>(document.createElement('div'));
        this.tiers.node.classList.add('tiers');

        this.needs = new StaticList<ResourceNeedRow, string>(document.createElement('div'));
        this.needs.node.setAttribute('data-table', 'Needs');

        this.costs = new PieChart<string>(type.tooltipCashFlowItem);
        this.budget = new PieChart<string>(type.tooltipBudgetItem);

        const left: HTMLDivElement = document.createElement('div');

        const charts: [PieChart<any>, string][] = [
            [this.costs, 'Costs'],
            [this.budget, 'Budget'],
        ];

        for (const [chart, label] of charts) {
            const container: HTMLElement = document.createElement('figure');
            const caption: HTMLElement = document.createElement('figcaption');
            caption.textContent = label;
            container.appendChild(caption);
            container.appendChild(chart.node);
            left.appendChild(container);
        }

        this.terms = new StaticList<Term, string>(document.createElement('ul'));
        this.terms.node.classList.add('terms');

        left.classList.add('pie-charts');

        this.charts = document.createElement('div');
        this.charts.appendChild(left);
        this.charts.appendChild(this.terms.node);
        this.charts.classList.add('hstack');

        this.node = document.createElement('div');
        this.node.classList.add('consumption');
        this.node.appendChild(this.tiers.node);
        this.node.appendChild(this.needs.node);
        this.node.appendChild(this.charts);
    }

    public update(id: GameID, state: InventoryBreakdownState<any>, type: PersistentOverviewType): void {
        this.tiers.update(
            state.tiers,
            (tier: ResourceNeedMeterState) => new ResourceNeedMeter(tier.id, id, type),
            (
                tier: ResourceNeedMeterState,
                meter: ResourceNeedMeter
            ) => meter.update(tier, type.screen),
            state.focus
        );
        this.needs.update(
            state.needs,
            (need: ResourceNeed) => new ResourceNeedRow(need, id, type),
            (need: ResourceNeed, row: ResourceNeedRow) => row.update(need, id),
        );
        this.terms.update(
            state.terms,
            (term: TermState) => new Term(term),
            (term: TermState, item: Term) => item.update(term, [id]),
        );

        this.costs.update([id], state.costs ?? []);
        this.budget.update([id], state.budget ?? []);
    }
}
