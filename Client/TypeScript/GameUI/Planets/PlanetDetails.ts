import { GameID } from '../../GameEngine/exports.js';
import { PlanetGrid } from '../exports.js';

export interface PlanetDetails {
    readonly id: GameID;
    readonly open: PlanetGrid;
}
