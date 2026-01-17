import { CandlestickState, TickRuleState } from '../exports.js';

export interface TradingViewState {
    readonly history: CandlestickState[];
    readonly min: number;
    readonly max: number;
    readonly maxv: bigint;
    readonly ticks: TickRuleState[];
}
