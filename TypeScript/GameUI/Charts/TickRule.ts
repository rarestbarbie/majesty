import {
    DiffableListElement,
    UpdateText,
} from '../../DOM/exports.js';
import {
    UpdateColorReference,
} from '../../GameEngine/exports.js';
import { TickRuleState } from '../exports.js';

export class TickRule implements DiffableListElement<number> {
    public readonly id: number;
    public readonly node: HTMLDivElement;
    private readonly body: HTMLDivElement;

    constructor(tick: TickRuleState) {
        this.id = tick.id;

        this.body = document.createElement('div');

        this.node = document.createElement('div');
        this.node.setAttribute('data-id', tick.id.toString());
        this.node.appendChild(this.body);

    }

    public update(tick: TickRuleState): void {
        this.node.style.setProperty('--y', tick.y.toString());

        UpdateText(this.body, tick.text);

        if (tick.grid === true) {
            this.node.setAttribute('data-tick-type', 'grid');
        } else {
            this.node.setAttribute('data-tick-type', 'arrow');
        }
        if (tick.label !== undefined) {
            UpdateColorReference(this.node, tick.label);
        }
    }
}
