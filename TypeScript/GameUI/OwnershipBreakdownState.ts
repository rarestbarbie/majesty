import { PieChartSector } from './exports.js';
import { GameID } from '../GameEngine/exports.js';

export interface OwnershipBreakdownState<Type extends string> {
    readonly type: Type;
    readonly culture?: PieChartSector<string>[];
    readonly country?: PieChartSector<GameID>[];
    readonly shares?: bigint;
    readonly y_px?: number;
    readonly y_pa?: number;
    readonly t_px?: number;
    readonly t_pa?: number;
}
