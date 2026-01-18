import { PieChartSectorState } from './exports.js';
import { GameID } from '../GameEngine/exports.js';
import { TermState } from '../DOM/exports.js';

export interface OwnershipBreakdownState<Type extends string> {
    readonly type: Type;
    readonly culture?: PieChartSectorState<GameID>[];
    readonly country?: PieChartSectorState<GameID>[];
    readonly gender?: PieChartSectorState<string>[];
    readonly terms?: TermState[];
}
