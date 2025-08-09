import {
    Fortune,
    UpdateBigInt,
    UpdatePrice,
    UpdateText,
} from '../exports.js';

export class Ticker {
    readonly outer: HTMLSpanElement;
    readonly value: HTMLSpanElement;
    readonly delta: HTMLSpanElement;

    constructor(fortune: Fortune) {
        this.outer = document.createElement('span');
        this.value = document.createElement('span');
        this.delta = document.createElement('span');

        this.outer.appendChild(this.value);
        this.outer.appendChild(this.delta);
        this.outer.dataset['ticker'] = fortune;
    }

    public updatePriceChange(yesterday: number, today: number, places: number = 2): void {
        this.updatePrices(today, today - yesterday, places);
    }

    public updateBigIntChange(yesterday: bigint, today: bigint): void {
        this.updateBigInts(today, today - yesterday);
    }


    public updatePrices(value: number, delta: number, places: number = 2): void {
        UpdatePrice(this.value, value, places);

        const magnitude: string = delta.toLocaleString(
            undefined,
            {
                minimumFractionDigits: places,
                maximumFractionDigits: places,
                signDisplay: 'never'
            }
        );

        UpdateText(this.delta, magnitude);

        if (delta < 0) {
            this.delta.dataset['sign'] = 'neg';
        } else if (delta > 0) {
            this.delta.dataset['sign'] = 'pos';
        } else {
            this.delta.dataset['sign'] = 'zero';
        }
    }

    public updateBigInts(value: bigint, delta: bigint): void {
        UpdateBigInt(this.value, value);

        if (delta > 0) {
            UpdateBigInt(this.delta, delta);
            this.delta.dataset['sign'] = 'pos';
        } else if (delta < 0) {
            UpdateBigInt(this.delta, -delta);
            this.delta.dataset['sign'] = 'neg';
        } else {
            UpdateText(this.delta, '0');
            this.delta.dataset['sign'] = 'zero';
        }
    }
}
