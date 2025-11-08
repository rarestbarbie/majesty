import { Color, GameID } from '../GameEngine/exports.js';

export interface Country {
    id: GameID;
    article: string;
    name: string;
    long: string;
    color: Color;
    white: string;
    accepted: string[];
    territory: GameID[];
}
