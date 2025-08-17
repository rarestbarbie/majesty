import { GameID } from '../../GameEngine/exports.js';
import { NavigatorState, HexGrid } from '../exports.js';

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

    public update(navigator: NavigatorState): void {
        if (!navigator.minimap) {
            return;
        }

        this.name.innerText = navigator.minimap.name;

        const id: GameID = navigator.minimap.id;

        if (this.id !== id) {
            this.id = id;
            this.grid.switch();
        }

        this.grid.update(
            navigator.minimap.grid,
            [id],
            (cell: string) => `#planet=${id}&cell=${cell}`,
            navigator.tile?.id,
        );
    }
}
