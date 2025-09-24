import { PieChartSector } from '../exports.js';
import { GameID } from '../../GameEngine/exports.js';

export interface OwnershipBreakdown<Type extends string> {
    readonly type: Type;
    readonly culture?: PieChartSector<string>[];
    readonly country?: PieChartSector<GameID>[];
}
