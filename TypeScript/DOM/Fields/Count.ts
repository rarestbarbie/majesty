import { CountInstruction, UpdateText } from '../exports.js';

export class Count {
    readonly outer: HTMLSpanElement;
    private readonly value: HTMLSpanElement;
    private readonly limit: HTMLSpanElement;

    constructor() {
        this.value = document.createElement('span');
        this.limit = document.createElement('span');
        this.outer = document.createElement('span');
        this.outer.appendChild(this.value);
        this.outer.appendChild(this.limit);
    }

    public update(instruction: CountInstruction): void {
        this.outer.dataset['count'] = instruction.fortune;
        this.value.dataset['sign'] = instruction.sign ?? 'zero';
        UpdateText(this.value, instruction.value);
        UpdateText(this.limit, instruction.limit);

    }
    // public updateBigInt(count: bigint, limit: bigint): void {
    //     UpdateText(this.value, count.toLocaleString());
    //     UpdateText(this.limit, limit.toLocaleString());

    //     if (count < limit) {
    //         this.outer.dataset['count'] = 'under';
    //     } else if (count == limit) {
    //         this.outer.dataset['count'] = 'full';
    //     } else {
    //         this.outer.dataset['count'] = 'over';
    //     }
    // }
}
