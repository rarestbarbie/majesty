import { GameID } from '../../GameEngine/exports.js';
import { PieChartSectorState } from '../exports.js';

export interface NavigatorTileState {
    readonly id: string;
    readonly name: string;
    readonly terrain: string;
    readonly culture?: PieChartSectorState<GameID>[];
    readonly popType?: PieChartSectorState<string>[];

    readonly _neighbors: string[];
}
