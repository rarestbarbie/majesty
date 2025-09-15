import { Color } from '../../GameEngine/exports.js';

export interface PlanetMapTileState {
    readonly id: string;
    readonly d0: string;
    readonly d1?: string;
    readonly color?: Color;
    readonly x?: number;
    readonly y?: number;
    readonly z?: number;
}
