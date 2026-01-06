import { GameID } from '../../GameEngine/exports.js';
import { PlanetMapTileState } from '../exports.js';

export interface MinimapState {
    id: GameID;
    name: string;
    grid: PlanetMapTileState[];
    layer: string;
}
