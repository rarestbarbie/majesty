import { Term, TermState, Fortune, Ticker } from '../DOM/exports.js';
import { GameID } from '../GameEngine/exports.js';
import {
    OwnershipBreakdownState,
    PieChart,
    TooltipType,
} from './exports.js';
import {
    StaticList
} from '../DOM/exports.js';

export class OwnershipBreakdown {
    public readonly node: HTMLDivElement;

    private readonly byCountry: PieChart<GameID>;
    private readonly byCulture: PieChart<GameID>;

    private readonly terms: StaticList<Term, string>;

    constructor(
        tooltipCountry: TooltipType,
        tooltipCulture: TooltipType,
    ) {
        this.byCountry = new PieChart<GameID>(tooltipCountry);
        this.byCulture = new PieChart<GameID>(tooltipCulture);

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

        this.terms = new StaticList<Term, string>(document.createElement('ul'));
        this.terms.node.classList.add('terms');

        left.classList.add('pie-charts');

        this.node = document.createElement('div');
        this.node.appendChild(left);
        this.node.appendChild(this.terms.node);
        this.node.classList.add('hstack');
    }

    public update(id: GameID, state: OwnershipBreakdownState<any>): void {
        this.byCountry.update([id], state.country ?? []);
        this.byCulture.update([id], state.culture ?? []);

        this.terms.update(
            state.terms ?? [],
            (term: TermState) => new Term(term),
            (term: TermState, item: Term) => item.update(term, [id]),
        );
    }
}
