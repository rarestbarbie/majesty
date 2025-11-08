import { CandlestickChartInterval } from '../exports.js';

export interface CandlestickChart {
    readonly history: CandlestickChartInterval[];
    readonly min: number;
    readonly max: number;
    readonly maxv: bigint;
}
