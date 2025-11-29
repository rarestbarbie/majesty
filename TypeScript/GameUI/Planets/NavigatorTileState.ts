import { GameID } from '../../GameEngine/exports.js';
import { PieChartSector } from '../exports.js';

export interface NavigatorTileState {
    readonly id: string;
    readonly name: string;
    readonly terrain: string;
    readonly culture?: PieChartSector<GameID>[];
    readonly popType?: PieChartSector<string>[];

    readonly _neighbors: string[];
}
