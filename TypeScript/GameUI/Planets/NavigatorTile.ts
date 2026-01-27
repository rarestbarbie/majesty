import { GameID } from '../../GameEngine/exports.js';
import {
    NavigatorTileState,
    PieChart,
    TooltipType,
} from '../exports.js';

export class NavigatorTile {
    readonly node: HTMLDivElement;
    private readonly header: HTMLElement;
    private readonly detail: HTMLDivElement;

    private readonly charts: {
        readonly race: PieChart<GameID>;
        readonly occupation: PieChart<string>;
    };

    constructor() {
        this.header = document.createElement('header');

        this.charts = {
            race: new PieChart<GameID>(TooltipType.TilePopRace),
            occupation: new PieChart<string>(TooltipType.TilePopOccupation),
        };

        this.detail = document.createElement('div');
        this.detail.appendChild(this.charts.race.node);
        this.detail.appendChild(this.charts.occupation.node);

        this.node = document.createElement('div');
        this.node.id = 'tile';
        this.node.appendChild(this.header);
        this.node.appendChild(this.detail);

        this.node.style.display = 'none';
    }

    public update(tile: NavigatorTileState | undefined): void {
        if (!tile) {
            this.node.style.display = 'none';
            return;
        } else {
            this.node.style.display = 'block';
        }

        this.header.innerText = tile.name;

        if (tile.race !== undefined) {
            this.charts.race.update(tile.race, tile.id);
        }
        if (tile.occupation !== undefined) {
            this.charts.occupation.update(tile.occupation, tile.id);
        }
    }
}
