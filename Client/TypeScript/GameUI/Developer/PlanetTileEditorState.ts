import { PlanetTile } from '../exports.js';

export interface PlanetTileEditorState {
    id: string;

    rotate?: boolean;
    size: number;
    type: number;
    terrainChoices: number[];
    terrainLabels: string[];
    tile: PlanetTile;
}
