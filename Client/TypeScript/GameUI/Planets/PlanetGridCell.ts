import { Color } from '../../GameEngine/exports.js';

export interface PlanetGridCell {
    readonly id: string;
    readonly d0: string;
    readonly d1?: string;
    readonly color: Color;
}
