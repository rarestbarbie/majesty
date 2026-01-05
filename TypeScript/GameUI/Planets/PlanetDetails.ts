import { GameID } from '../../GameEngine/exports.js';

export interface PlanetDetails {
    readonly id: GameID;
    readonly open: string;
    readonly name?: string;
}
