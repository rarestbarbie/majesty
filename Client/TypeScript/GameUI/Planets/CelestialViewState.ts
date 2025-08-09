import { GameID } from '../../GameEngine/exports.js';
import { CelestialBodyState } from '../exports.js';

export interface CelestialViewState {
    readonly subject: GameID;
    readonly bodies: CelestialBodyState[];
    readonly radius: number;
}
