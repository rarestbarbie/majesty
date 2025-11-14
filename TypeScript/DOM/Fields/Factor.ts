import { FactorInstruction, UpdateText } from '../exports.js';

export class Factor {
    readonly outer: HTMLSpanElement;

    constructor() {
        this.outer = document.createElement('span');
    }

    public update(instruction: FactorInstruction): void {
        this.outer.dataset['sign'] = instruction.sign ?? 'zero';
        this.outer.dataset['factor'] = instruction.fortune;
        UpdateText(this.outer, instruction.value);
    }
}
