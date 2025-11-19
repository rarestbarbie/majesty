import {
    DiffableListElement,
    UpdateText,
} from '../DOM/exports.js';
import { GameID } from '../GameEngine/exports.js';
import {
    PersistentOverviewType,
    ProgressCell,
    ResourceNeedMeterState,
    ScreenType,
} from './exports.js';

export class ResourceNeedMeter implements DiffableListElement<string> {
    public readonly id: string;
    public readonly cell: ProgressCell;
    private readonly name: HTMLAnchorElement;

    constructor(id: string, type: PersistentOverviewType) {
        this.id = id;
        this.name = document.createElement('a');
        const summary: HTMLSpanElement = document.createElement('span');
        summary.appendChild(this.name);
        this.cell = new ProgressCell(summary);

        this.cell.node.setAttribute('data-tooltip-type', type.tooltipNeeds);

    }

    public update(state: ResourceNeedMeterState, owner: GameID, screen: ScreenType): void {
        this.cell.set(100 * state.value);
        this.cell.node.setAttribute('data-tier', this.id);
        this.name.href = `#screen=${screen}&detailsTier=${this.id}`;
        UpdateText(this.name, state.label);

        this.cell.node.setAttribute(
            'data-tooltip-arguments',
            JSON.stringify([owner, this.id])
        );
    }

    public get node(): HTMLDivElement {
        return this.cell.node;
    }
}
