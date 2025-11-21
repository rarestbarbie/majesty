import { Color, GameID } from '../GameEngine/exports.js';

export interface Country {
    id: GameID;
    name: { long: string; color: Color; };
}
