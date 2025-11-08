import { Candle } from './exports.js';

export interface ResourceNeed {
    readonly id: string;
    readonly name: string;
    readonly icon: string;
    readonly tier: 'l' | 'e' | 'x';
    readonly stockpile?: bigint
    readonly filled: bigint
    readonly demand: bigint
    readonly price?: Candle<number>;
}
