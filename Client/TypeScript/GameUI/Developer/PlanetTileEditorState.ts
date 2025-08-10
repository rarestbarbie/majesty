import { PlanetTile } from '../exports.js';

export interface PlanetTileEditorState {
    rotate?: boolean;
    size: number;
    type: number;
    terrainChoices: number[];
    terrainLabels: string[];
    tile: PlanetTile;
}
