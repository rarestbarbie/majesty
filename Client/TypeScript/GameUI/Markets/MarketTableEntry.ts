import { Candle } from '../exports.js';

export interface MarketTableEntry {
    readonly id: string;
    readonly name: string;
    readonly price: Candle<number>;
    readonly volume: bigint;
}
