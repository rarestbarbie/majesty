import { TermState } from '../../DOM/exports.js';
import { TradingViewState } from '../exports.js';

export interface MarketDetails {
    readonly id: string;
    readonly name?: string;
    readonly chart: TradingViewState;
    readonly terms: TermState[];
}
