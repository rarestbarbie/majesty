import { TimeSeriesChannelState, TickRuleState } from '../exports.js';

export interface TimeSeriesState {
    readonly channels: TimeSeriesChannelState<number>[];
    readonly min: number;
    readonly max: number;
    readonly ticks: TickRuleState[];
    readonly d?: string;
}
