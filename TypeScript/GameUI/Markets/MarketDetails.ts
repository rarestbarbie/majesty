import { TradingViewState } from '../exports.js';

export interface MarketDetails {
    readonly id: string;
    readonly chart: TradingViewState;
}
