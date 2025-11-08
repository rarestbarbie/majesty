import { GameID } from '../../GameEngine/exports.js';
import { PlanetMapState } from '../exports.js';

export interface PlanetDetails {
    readonly id: GameID;
    readonly open: PlanetMapState;
}
