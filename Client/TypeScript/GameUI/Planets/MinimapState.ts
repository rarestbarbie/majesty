import { GameID } from '../../GameEngine/exports.js';
import { PlanetGridCell } from '../exports.js';

export interface MinimapState {
    id: GameID;
    name: string;
    grid: PlanetGridCell[];
}
