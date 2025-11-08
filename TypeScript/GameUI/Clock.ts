import { UpdateText } from '../DOM/exports.js';
import { Color, GameDateComponents, hex } from '../GameEngine/exports.js';
import {
    GameUI,
} from './exports.js';
import { Swift } from '../Swift.js';

export class Clock {
    public readonly node: HTMLElement;
    public readonly pause: HTMLButtonElement;
    public readonly faster: HTMLButtonElement;
    public readonly slower: HTMLButtonElement;

    // This needs to be its own <span>, because on some browsers (Safari), dynamically
    // updating the content of the pause button interferes with event propagation.
    private readonly date: HTMLTimeElement;
    private readonly flag: HTMLElement;

    public constructor() {
        this.node = document.createElement('div');
        this.flag = document.createElement('div');
        this.date = document.createElement('time');
        this.pause = document.createElement('button');
        this.faster = document.createElement('button');
        this.faster.id = 'faster';
        this.slower = document.createElement('button');
        this.slower.id = 'slower';

        this.flag.id = 'flag';
        this.pause.appendChild(this.date);

        this.node.appendChild(this.flag);
        this.node.appendChild(this.pause);
        this.node.appendChild(this.slower);
        this.node.appendChild(this.faster);
        this.node.id = 'clock';
    }

    public update(state: GameUI) {
        const date: GameDateComponents = Swift.gregorian(state.date);
        let month: string = '';
        switch (date.m) {
            case 1: month = 'January'; break;
            case 2: month = 'February'; break;
            case 3: month = 'March'; break;
            case 4: month = 'April'; break;
            case 5: month = 'May'; break;
            case 6: month = 'June'; break;
            case 7: month = 'July'; break;
            case 8: month = 'August'; break;
            case 9: month = 'September'; break;
            case 10: month = 'October'; break;
            case 11: month = 'November'; break;
            case 12: month = 'December'; break;
        }

        this.node.classList.toggle('paused', state.speed.paused);
        this.node.dataset.ticks = `${state.speed.ticks}`;
        // Convert Int32 color to CSS hex string
        this.flag.style.backgroundColor = hex(state.player?.color ?? 0x000000 as Color);
        this.flag.title = state.player?.long ?? 'Observer';
        UpdateText(this.date, `${month} ${date.d}, ${date.y}`);
    }
}
