import {
    DiffableListElement,
    UpdateText,
} from '../../DOM/exports.js';
import { TradingViewTickState } from '../exports.js';

export class TradingViewTick implements DiffableListElement<number> {
    public readonly id: number;
    public readonly node: HTMLDivElement;
    private readonly body: HTMLDivElement;

    constructor(tick: TradingViewTickState) {
        this.id = tick.id;

        this.body = document.createElement('div');

        this.node = document.createElement('div');
        this.node.setAttribute('data-id', tick.id.toString());
        this.node.appendChild(this.body);

    }

    public update(tick: TradingViewTickState): void {
        UpdateText(this.body, tick.l);
        this.node.style.setProperty('--y', tick.p.toString());
        if (tick.s !== undefined) {
            this.node.setAttribute('data-style', tick.s);
        } else {
            this.node.removeAttribute('data-style');
        }
    }
}
