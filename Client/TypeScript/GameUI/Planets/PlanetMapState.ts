import { PlanetDetailsTab, PlanetMapTileState } from '../exports.js';

export interface PlanetMapState {
    readonly type: PlanetDetailsTab.Grid;
    readonly size: number;
    readonly tiles: PlanetMapTileState[];
}
