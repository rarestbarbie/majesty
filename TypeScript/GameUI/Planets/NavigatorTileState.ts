import { GameID } from '../../GameEngine/exports.js';
import { PieChartSectorState } from '../exports.js';

export interface NavigatorTileState {
    readonly id: string;
    readonly name: string;
    readonly terrain: string;
    readonly race?: PieChartSectorState<GameID>[];
    readonly occupation?: PieChartSectorState<string>[];

    readonly _neighbors: string[];
}
