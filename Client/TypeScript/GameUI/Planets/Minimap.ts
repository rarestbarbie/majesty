import { GameID } from '../../GameEngine/exports.js';
import { NavigatorState, HexGrid, MinimapState, MinimapLayer } from '../exports.js';

export class Minimap {
    readonly node: HTMLDivElement;
    private readonly name: HTMLElement;
    private readonly grid: HexGrid;
    private readonly layers: HTMLElement;
    private layerShown?: MinimapLayer;
    private id?: GameID;

    constructor() {
        this.name = document.createElement('header');
        this.grid = new HexGrid();
        this.layers = document.createElement('nav');

        this.node = document.createElement('div');
        this.node.id = 'minimap';
        this.node.appendChild(this.name);
        this.node.appendChild(this.grid.node);
        this.node.appendChild(this.layers);
    }

    public update(navigator: NavigatorState): void {
        if (!navigator.minimap) {
            return;
        }

        const minimap: MinimapState = navigator.minimap;
        if (this.layerShown !== minimap.layer) {
            this.layerShown = minimap.layer;
            this.grid.switch();
        }

        this.name.innerText = minimap.name;

        const id: GameID = minimap.id;

        if (this.id !== id) {
            this.id = id;
            this.grid.switch();
            this.updateLayerControls(minimap.id, minimap.layer);
        } else {
            // Highlight the active layer
            for (const child of this.layers.children) {
                const link = child as HTMLAnchorElement;
                link.classList.toggle('selected', link.dataset.layer === minimap.layer);
            }
        }

        this.grid.update(
            minimap.grid,
            minimap.layer,
            [id],
            (cell: string) => `#planet=${id}&cell=${cell}`,
            navigator.tile?.id,
        );
    }

    private updateLayerControls(planet: GameID, selected: MinimapLayer): void {
        this.layers.replaceChildren(); // Clear existing icons

        const icons: Record<MinimapLayer, string> = {
            [MinimapLayer.Terrain]: '🗺️',
            [MinimapLayer.Population]: '🧑‍🤝‍🧑',
            [MinimapLayer.AverageMilitancy]: '😠',
            [MinimapLayer.AverageConsciousness]: '🤔',
        };

        for (const layer of Object.values(MinimapLayer)) {
            const link: HTMLAnchorElement = document.createElement('a');
            link.href = `#planet=${planet}&layer=${layer}`;
            link.dataset.layer = layer;
            link.textContent = icons[layer];
            link.classList.toggle('selected', layer === selected);
            this.layers.appendChild(link);
        }
    }
}
