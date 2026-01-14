import {
    DiffableListElement,
} from '../../DOM/exports.js';
import { GameDate } from '../../GameEngine/exports.js';
import { CandlestickState } from '../exports.js';

export class Candlestick implements DiffableListElement<GameDate> {
    public readonly id: GameDate;
    public readonly node: HTMLDivElement;
    private readonly body: HTMLDivElement;
    private readonly wick: HTMLDivElement;
    private readonly volume: HTMLDivElement;

    constructor(interval: CandlestickState) {
        this.id = interval.id;
        this.node = document.createElement('div');
        this.body = document.createElement('div');
        this.wick = document.createElement('div');
        this.volume = document.createElement('div');

        this.node.appendChild(this.volume);
        this.node.appendChild(this.wick);
        this.node.appendChild(this.body);
    }

    public update(interval: CandlestickState): void {
        const { o: open, h: high, l: low, c: close } = interval.c;

        this.node.style.setProperty('--o', open.toString());
        this.node.style.setProperty('--c', close.toString());
        this.node.style.setProperty('--l', low.toString());
        this.node.style.setProperty('--h', high.toString());

        this.volume.style.setProperty('--v', interval.v.toString());

        // this.body.dataset['o'] = open.toString();
        // this.body.dataset['c'] = close.toString();

        // this.wick.dataset['l'] = low.toString();
        // this.wick.dataset['h'] = high.toString();

        if (close > open) {
            this.node.dataset['change'] = 'pos';
        } else if (close < open) {
            this.node.dataset['change'] = 'neg';
        } else {
            this.node.dataset['change'] = 'zero';
        }
    }
}
