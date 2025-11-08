import { GameID, Color } from '../../GameEngine/exports.js';

export interface CelestialBodyState {
    readonly id: GameID;
    readonly at: [number, number, number];
    readonly name: string;
    readonly size: number;
    readonly color: Color;
    readonly sprite_x: number;
    readonly sprite_y: number;
    readonly sprite_size: number;
    readonly sprite_disk: number;
}
