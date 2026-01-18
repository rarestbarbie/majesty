import { ColorReference } from '../../GameEngine/exports.js';
import { TimeSeriesFrameState } from '../exports.js';

export interface TimeSeriesChannelState<ID> {
    readonly id: ID;
    readonly d: string;
    readonly frames?: TimeSeriesFrameState[];
    readonly label?: ColorReference;
}
