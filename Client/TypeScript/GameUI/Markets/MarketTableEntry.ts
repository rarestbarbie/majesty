import { Candle } from '../exports.js';

export interface MarketTableEntry {
    readonly id: string;
    readonly name: string;
    readonly price: Candle<number>;
    readonly liq_base: bigint;
    readonly liq_quote: bigint;
}
