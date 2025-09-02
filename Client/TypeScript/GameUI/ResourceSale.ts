import { Candle, Resource } from './exports.js';

export interface ResourceSale {
    readonly id: Resource;
    readonly name: string;
    readonly icon: string;

    readonly unitsProduced: bigint;
    readonly unitsSold: bigint;
    readonly valueSold: bigint;

    readonly priceAtMarket?: Candle<number>;
    readonly price?: Candle<bigint>;
}
