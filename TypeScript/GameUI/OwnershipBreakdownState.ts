import { PieChartSector } from './exports.js';
import { GameID } from '../GameEngine/exports.js';
import { TermState } from '../DOM/exports.js';

export interface OwnershipBreakdownState<Type extends string> {
    readonly type: Type;
    readonly culture?: PieChartSector<string>[];
    readonly country?: PieChartSector<GameID>[];
    readonly terms?: TermState[];
}
