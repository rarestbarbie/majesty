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
    TooltipType,
} from './exports.js';

export class InventoryCharts {
    public readonly node: HTMLDivElement;

    private readonly costs: PieChart<string>;
    private readonly budget: PieChart<string>;
    private readonly terms: StaticList<Term, string>;

    constructor(type: PersistentOverviewType) {
        this.costs = new PieChart<string>(type.tooltipCashFlowItem);
        this.budget = new PieChart<string>(type.tooltipBudgetItem);

        const charts: [PieChart<any>, string][] = [
            [this.costs, 'Costs'],
            [this.budget, 'Budget'],
        ];

        const top: HTMLDivElement = document.createElement('div');
        top.classList.add('pie-charts');

        for (const [chart, label] of charts) {
            const container: HTMLElement = document.createElement('figure');
            const caption: HTMLElement = document.createElement('figcaption');
            caption.textContent = label;
            container.appendChild(caption);
            container.appendChild(chart.node);
            top.appendChild(container);
        }


        this.terms = new StaticList<Term, string>(document.createElement('ul'));
        this.terms.node.classList.add('terms');

        this.node = document.createElement('div');
        this.node.appendChild(top);
        this.node.appendChild(this.terms.node);
        this.node.classList.add('inventory-charts');
    }

    public update(id: GameID, state: InventoryBreakdownState<any>): void {
        this.terms.update(
            state.terms,
            (term: TermState) => new Term(term),
            (term: TermState, item: Term) => item.update(term, [id]),
        );

        this.costs.update(state.costs ?? [], id);
        this.budget.update(state.budget ?? [], id);
    }
}
