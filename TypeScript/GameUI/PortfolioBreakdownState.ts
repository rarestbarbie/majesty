import { PieChartSectorState } from './exports.js';
import { GameID } from '../GameEngine/exports.js';
import { TermState } from '../DOM/exports.js';

export interface PortfolioBreakdownState<Type extends string> {
    readonly type: Type;
    readonly country?: PieChartSectorState<GameID>[];
    readonly industry?: PieChartSectorState<string>[];
    readonly terms?: TermState[];
}
