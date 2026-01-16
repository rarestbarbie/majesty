import { TimeSeriesFrameState, TickRuleState } from '../exports.js';

export interface TimeSeriesState {
    readonly history: TimeSeriesFrameState[];
    readonly min: number;
    readonly max: number;
    readonly ticks: TickRuleState[];
}
