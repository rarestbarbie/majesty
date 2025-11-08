import { PlanetTile } from '../exports.js';

export interface PlanetTileEditorState {
    id: string;

    rotate?: boolean;
    size: number;
    name?: string;
    terrain: string;
    terrainChoices: string[];
    geology: string;
    geologyChoices: string[];
}
