import { Candle, Resource } from './exports.js';

export interface ResourceNeed {
    readonly id: Resource;
    readonly name: string;
    readonly icon: string;
    readonly tier: 'l' | 'e' | 'x' | 'i' | 'v';
    readonly unitsAcquired?: bigint
    readonly unitsCapacity?: bigint
    readonly unitsDemanded: bigint
    readonly unitsConsumed: bigint
    readonly priceAtMarket?: Candle<number>;
    readonly price?: Candle<bigint>;
}
