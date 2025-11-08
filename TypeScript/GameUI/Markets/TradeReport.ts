import {
    MarketDetails,
    MarketFilterLabel,
    MarketTableEntry,
    ScreenType,
} from '../exports.js';

export interface TradeReport {
    readonly type: ScreenType.Trade;
    readonly markets: MarketTableEntry[];
    readonly market?: MarketDetails;
    readonly filter?: string;
    readonly filterlist?: number;
    readonly filterlists: MarketFilterLabel[][];
}
