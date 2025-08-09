import { Color } from '../../GameEngine/exports.js';

export interface PlanetGridCell {
    readonly id: string;
    readonly d: string;
    readonly color: Color;
}
