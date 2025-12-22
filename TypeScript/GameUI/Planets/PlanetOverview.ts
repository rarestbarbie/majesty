import {
    ScreenContent,
    HexGrid,
    PlanetDetailsTab,
    PlanetMapState,
    PlanetReport,
    MinimapLayer,
} from '../exports.js';
import { Swift } from '../../Swift.js';
import { GameID } from '../../GameEngine/exports.js';

export class PlanetOverview extends ScreenContent {
    private readonly grid: HexGrid;

    private dom?: {
        readonly panel: HTMLDivElement;
    };

    constructor() {
        super();
        this.grid = new HexGrid();
    }

    public override async open(parameters: URLSearchParams): Promise<void> {
        const idString: string | null = parameters.get('id');
        if (!idString) {
            console.error("PlanetOverview: No planet ID found in URL parameters.");
            return;
        }
        const id: GameID = parseInt(idString) as GameID;

        if (this.dom === undefined) {
            this.dom = {
                panel: document.createElement('div'),
            };
            this.dom.panel.classList.add('planet-overview');
            this.dom.panel.appendChild(this.grid.node);
        }

        const state: PlanetReport | null = await Swift.openPlanet({ subject: id });
        if (!state) {
            console.error(`PlanetOverview: Could not retrieve report for planet ID ${id}.`);
            return;
        }

        this.update(state);
    }

    public override attach(root: HTMLElement): void {
        if (this.dom !== undefined) {
            root.appendChild(this.dom.panel);
        }
    }
    public override detach(): void {
        if (this.dom !== undefined) {
            this.dom.panel.remove();
            this.dom = undefined;
        }
    }

    public update(state: PlanetReport): void {
        if (this.dom === undefined) {
            return;
        }

        // The 'open' property contains the grid data, as per your extensible design.
        const grid: PlanetMapState = state.planet.open;
        this.grid.update(grid.tiles, MinimapLayer.Terrain, [state.planet.id]);
    }
}
