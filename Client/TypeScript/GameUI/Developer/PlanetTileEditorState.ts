import { PlanetTile } from '../exports.js';

export interface PlanetTileEditorState {
    size: number;
    type: number;
    terrainChoices: number[];
    terrainLabels: string[];
    tile: PlanetTile;
}
