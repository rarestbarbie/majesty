import {
    DiffableListElement,
    UpdateText,
} from '../DOM/exports.js';
import {
    ProgressCell,
    ResourceNeedMeterState,
    ScreenType,
} from './exports.js';

export class ResourceNeedMeter implements DiffableListElement<string> {
    public readonly id: string;
    public readonly cell: ProgressCell;
    private readonly name: HTMLAnchorElement;

    constructor(id: string) {
        this.id = id;
        this.name = document.createElement('a');
        const summary: HTMLSpanElement = document.createElement('span');
        summary.appendChild(this.name);
        this.cell = new ProgressCell(summary);
    }

    public update(state: ResourceNeedMeterState, screen: ScreenType): void {
        this.cell.set(100 * state.value);
        this.cell.node.setAttribute('data-tier', this.id);
        this.name.href = `#screen=${screen}&detailsTier=${this.id}`;
        UpdateText(this.name, state.label);
    }

    public get node(): HTMLDivElement {
        return this.cell.node;
    }
}
