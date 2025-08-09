import { PlanetDetailsTab, PlanetGridCell } from '../exports.js';

export interface PlanetGrid {
    readonly type: PlanetDetailsTab.Grid;
    readonly size: number;
    readonly cells: PlanetGridCell[];
}
