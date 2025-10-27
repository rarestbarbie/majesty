import {
    StaticList
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

        this.charts = document.createElement('div');
        this.charts.appendChild(left);
        this.charts.appendChild(right);
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
            (tier: ResourceNeedMeterState) => new ResourceNeedMeter(tier.id),
            (
                tier: ResourceNeedMeterState,
                meter: ResourceNeedMeter
            ) => meter.update(tier, type.screen),
            state.focus
        );
        this.needs.update(
            state.needs,
            (need: ResourceNeed) => new ResourceNeedRow(need, type, id),
            (need: ResourceNeed, row: ResourceNeedRow) => row.update(need),
        );

        this.costs.update([id], state.costs ?? []);
        this.budget.update([id], state.budget ?? []);
    }
}
