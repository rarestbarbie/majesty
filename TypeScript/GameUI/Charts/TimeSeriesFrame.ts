import {
    DiffableListElement,
} from '../../DOM/exports.js';
import { GameDate } from '../../GameEngine/exports.js';
import {
    TimeSeriesFrameState,
    TooltipType
} from '../exports.js';

export class TimeSeriesFrame implements DiffableListElement<GameDate> {
    public readonly id: GameDate;
    public readonly node: HTMLDivElement;
    private readonly marker: HTMLDivElement;

    constructor(frame: TimeSeriesFrameState, tile: string, tooltip?: TooltipType) {
        this.id = frame.id;
        this.marker = document.createElement('div');
        this.node = document.createElement('div');
        this.node.appendChild(this.marker);

        if (tooltip !== undefined) {
            this.node.setAttribute('data-tooltip-type', tooltip);
            this.node.setAttribute('data-tooltip-arguments', JSON.stringify([tile, this.id]));
        }
    }

    public update(frame: TimeSeriesFrameState): void {
        this.marker.style.setProperty('--y', `${frame.y}`);
    }
}
