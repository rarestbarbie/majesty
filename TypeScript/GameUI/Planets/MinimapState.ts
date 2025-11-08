import { GameID } from '../../GameEngine/exports.js';
import { MinimapLayer, PlanetMapTileState } from '../exports.js';

export interface MinimapState {
    id: GameID;
    name: string;
    grid: PlanetMapTileState[];
    layer: MinimapLayer;
}
