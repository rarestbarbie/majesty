import { Fortune, Ticker } from '../../DOM/exports.js';
import { GameID } from '../../GameEngine/exports.js';
import {
    InventoryBreakdownState,
    PieChart,
    TooltipType,
} from '../exports.js';

export class ConsumptionBreakdown {
    public readonly node: HTMLDivElement;

    private readonly costs: PieChart<string>;
    private readonly budget: PieChart<string>;

    constructor(
        tooltipCashFlowItem: TooltipType,
        tooltipBudgetItem: TooltipType
    ) {
        this.costs = new PieChart<string>(tooltipCashFlowItem);
        this.budget = new PieChart<string>(tooltipBudgetItem);

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

        const right: HTMLDListElement = document.createElement('dl');
        const rows: [HTMLElement, string][] = [
        ];
        for (const [value, label] of rows) {
            const dt: HTMLElement = document.createElement('dt');
            dt.textContent = label;
            const dd: HTMLElement = document.createElement('dd');
            dd.appendChild(value);

            right.appendChild(dt);
            right.appendChild(dd);
        }

        left.classList.add('pie-charts');

        this.node = document.createElement('div');
        this.node.appendChild(left);
        this.node.appendChild(right);
        this.node.classList.add('hstack');
    }

    public update(id: GameID, state: InventoryBreakdownState<any>): void {
        this.costs.update([id], state.costs ?? []);
        this.budget.update([id], state.budget ?? []);
    }
}
