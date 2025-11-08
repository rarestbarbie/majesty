import { CandlestickChart } from '../exports.js';

export interface MarketDetails {
    readonly id: string;
    readonly chart: CandlestickChart;
}
