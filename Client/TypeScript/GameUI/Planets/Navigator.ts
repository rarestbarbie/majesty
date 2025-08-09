import { GameID } from '../../GameEngine/exports.js';
import { PlanetGridCell } from '../exports.js';

export interface Navigator {
    readonly planet?: {
        id: GameID;
        name: string;
        grid: PlanetGridCell[];
    };
    readonly tile?: {
        id: string;
        name?: string;
        terrain: string;
    }
}
