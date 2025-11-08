import {
    GameID
} from '../../GameEngine/exports.js';
import {
    TooltipType
} from '../exports.js';

export class PopIcon {
    readonly node: HTMLDivElement;
    readonly icon: HTMLSpanElement;

    constructor() {
        this.node = document.createElement('div');
        this.icon = document.createElement('span');
        this.node.appendChild(this.icon);

        this.node.setAttribute('data-tooltip-type', TooltipType.PopType);
    }

    public set(pop: {id: GameID, type: string} | null): void {
        if (pop !== null) {
            this.node.setAttribute('data-pop-type', pop.type);
            this.node.setAttribute('data-tooltip-arguments', JSON.stringify([pop.id]));
        } else {
            this.node.removeAttribute('data-pop-type');
            this.node.removeAttribute('data-tooltip-arguments');
        }
    }
}
