import { Fortune, Ticker } from '../../DOM/exports.js';
import { GameID } from '../../GameEngine/exports.js';
import {
    OwnershipBreakdownState,
    PieChart,
    TooltipType,
} from '../exports.js';

export class OwnershipBreakdown {
    public readonly node: HTMLDivElement;

    private readonly byCountry: PieChart<GameID>;
    private readonly byCulture: PieChart<string>;
    private readonly shares: Ticker;

    constructor(
        tooltipCountry: TooltipType,
        tooltipCulture: TooltipType,
        tooltipSecurities: TooltipType
    ) {
        this.node = document.createElement('div');
        this.byCountry = new PieChart<GameID>(tooltipCountry);
        this.byCulture = new PieChart<string>(tooltipCulture);

        const left: HTMLDivElement = document.createElement('div');

        const charts: [PieChart<any>, string][] = [
            [this.byCountry, 'Country'],
            [this.byCulture, 'Culture'],
        ];

        for (const [chart, label] of charts) {
            const container: HTMLElement = document.createElement('figure');
            const caption: HTMLElement = document.createElement('figcaption');
            caption.textContent = label;
            container.appendChild(caption);
            container.appendChild(chart.node);
            left.appendChild(container);
        }

        this.shares = new Ticker(Fortune.Bonus);
        this.shares.outer.setAttribute('data-tooltip-type', tooltipSecurities);

        const right: HTMLDListElement = document.createElement('dl');
        const rows: [HTMLElement, string][] = [
            [this.shares.outer, '🍰'],
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

        this.node.appendChild(left);
        this.node.appendChild(right);
    }

    public update(id: GameID, state: OwnershipBreakdownState<any>): void {
        this.shares.outer.setAttribute('data-tooltip-arguments', JSON.stringify([id]));

        this.byCountry.update([id], state.country ?? []);
        this.byCulture.update([id], state.culture ?? []);

        this.shares.updateBigInts(state.shares ?? 0n, 0n);
    }
}
