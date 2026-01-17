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
        readonly culture: PieChart<GameID>;
        readonly popType: PieChart<string>;
    };

    constructor() {
        this.header = document.createElement('header');

        this.charts = {
            culture: new PieChart<GameID>(TooltipType.TileCulture),
            popType: new PieChart<string>(TooltipType.TilePopType),
        };

        this.detail = document.createElement('div');
        this.detail.appendChild(this.charts.culture.node);
        this.detail.appendChild(this.charts.popType.node);

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

        if (tile.culture !== undefined) {
            this.charts.culture.update(tile.culture, tile.id);
        }
        if (tile.popType !== undefined) {
            this.charts.popType.update(tile.popType, tile.id);
        }
    }
}
