import { Candle } from './exports.js';

export interface ResourceSale {
    readonly id: string;
    readonly name: string;
    readonly icon: string;
    readonly source?: string;

    readonly unitsSold: bigint;

    readonly price?: Candle<number>;
}
