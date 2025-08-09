import { GameID } from '../../GameEngine/exports.js';
import { Navigator, HexGrid } from '../exports.js';

export class Minimap {
    readonly node: HTMLDivElement;
    private readonly name: HTMLElement;
    private readonly grid: HexGrid;
    private id?: GameID;

    constructor() {
        this.name = document.createElement('header');
        this.grid = new HexGrid();

        this.node = document.createElement('div');
        this.node.id = 'minimap';
        this.node.appendChild(this.name);
        this.node.appendChild(this.grid.node);
    }

    public update(navigator: Navigator): void {
        if (!navigator.planet) {
            return;
        }

        this.name.innerText = navigator.planet.name;

        const id: GameID = navigator.planet.id;

        if (this.id !== id) {
            this.id = id;
            this.grid.switch();
        }

        this.grid.update(
            navigator.planet.grid,
            [id],
            (cell: string) => `#planet=${id}&cell=${cell}`,
            navigator.tile?.id,
        );
    }
}
