import {
    Fortune,
    DiffableListElement,
    Ticker,
    UpdateBigInt,
    UpdateText,
    UpdateDecimal,
} from '../DOM/exports.js';
import { GameID } from '../GameEngine/exports.js';
import {
    ProgressCell,
    PopIcon,
    PopTableEntry,
    ScreenType,
    TooltipType,
} from './exports.js';

export class ProgressTriad {
    public readonly node: HTMLDivElement;

    public readonly l: HTMLDivElement;
    public readonly e: HTMLDivElement;
    public readonly x: HTMLDivElement;

    public readonly fl: HTMLSpanElement;
    public readonly fe: HTMLSpanElement;
    public readonly fx: HTMLSpanElement;

    constructor(id: GameID, tooltip: TooltipType) {
        this.fl = document.createElement('span');
        this.fe = document.createElement('span');
        this.fx = document.createElement('span');

        this.l = document.createElement('div');
        this.l.setAttribute('data-cell', 'progress');
        this.l.appendChild(this.fl);
        this.l.setAttribute('data-tooltip-type', tooltip);
        this.l.setAttribute('data-tooltip-arguments', JSON.stringify([id, 'l']));

        this.e = document.createElement('div');
        this.e.setAttribute('data-cell', 'progress');
        this.e.appendChild(this.fe);
        this.e.setAttribute('data-tooltip-type', tooltip);
        this.e.setAttribute('data-tooltip-arguments', JSON.stringify([id, 'e']));

        this.x = document.createElement('div');
        this.x.setAttribute('data-cell', 'progress');
        this.x.appendChild(this.fx);
        this.x.setAttribute('data-tooltip-type', tooltip);
        this.x.setAttribute('data-tooltip-arguments', JSON.stringify([id, 'x']));

        this.node = document.createElement('div');
        this.node.appendChild(this.l);
        this.node.appendChild(this.e);
        this.node.appendChild(this.x);
        this.node.classList.add('needs-cups');
    }

    public set(fl: number, fe: number, fx: number): void {
        this.l.style.setProperty('--progress', `${fl}%`);
        this.e.style.setProperty('--progress', `${fe}%`);
        this.x.style.setProperty('--progress', `${fx}%`);

        UpdateDecimal(this.fl, fl, 1);
        UpdateDecimal(this.fe, fe, 1);
        UpdateDecimal(this.fx, fx, 1);
    }
}
