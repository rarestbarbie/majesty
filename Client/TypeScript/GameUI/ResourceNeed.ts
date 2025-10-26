import { Candle } from './exports.js';

export interface ResourceNeed {
    readonly id: string;
    readonly name: string;
    readonly icon: string;
    readonly tier: 'l' | 'e' | 'x';
    readonly unitsAcquired?: bigint
    readonly unitsDemanded: bigint
    readonly unitsConsumed: bigint
    readonly price?: Candle<number>;
}
