import { StaticList } from '../../DOM/exports.js';
import { GameID } from '../../GameEngine/exports.js';
import {
    ActionType,
    NavigatorState,
    HexGrid,
    MinimapState,
    PlanetMapLayerSelector,
} from '../exports.js';

export class Minimap {
    readonly node: HTMLDivElement;
    private readonly name: HTMLElement;
    private readonly grid: HexGrid;
    private readonly layers: StaticList<PlanetMapLayerSelector, string>;
    private layerShown?: string;
    private id?: GameID;

    constructor() {
        this.name = document.createElement('header');
        this.grid = new HexGrid();
        this.layers = new StaticList<PlanetMapLayerSelector, string>(
            document.createElement('ul')
        );

        const nav: HTMLElement = document.createElement('nav');
        nav.appendChild(this.layers.node);

        this.node = document.createElement('div');
        this.node.id = 'minimap';
        this.node.appendChild(this.name);
        this.node.appendChild(this.grid.node);
        this.node.appendChild(nav);
    }

    public update(navigator: NavigatorState): void {
        if (!navigator.minimap) {
            return;
        }

        const minimap: MinimapState = navigator.minimap;

        this.name.innerText = minimap.name;
        // Tile ID is the cell ID with numeric prefix removed.
        // E.g. "399N1,1" -> "N1,1"

        // Map of neighbor ID to index in neighbors array.
        // const neighbors: Map<string, number> | undefined = navigator.tile !== undefined
        //     ? new Map(navigator.tile._neighbors.map((id, index) => [id, index]))
        //     : undefined;

        if (this.layerShown !== minimap.layer || this.id !== minimap.id) {
            this.layerShown = minimap.layer;
            this.id = minimap.id;
            this.grid.switch();
        }
        this.grid.update(
            minimap.grid,
            minimap.layer,
            (id: string) => `#action=${ActionType.Minimap}&planetTile=${id}`,
            navigator.tile?.id,
            // neighbors
        );
        this.layers.allocate(
            minimap.layers,
            (layer: string) => new PlanetMapLayerSelector(layer),
            minimap.layer
        );
    }
}
