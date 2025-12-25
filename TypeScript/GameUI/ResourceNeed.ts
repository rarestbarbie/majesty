import { Candle } from './exports.js';

export interface ResourceNeed {
    readonly id: string;
    readonly name: string;
    readonly icon: string;
    readonly tier: 'l' | 'e' | 'x';
    readonly demanded: bigint
    readonly acquired: bigint
    readonly fulfilled: number
    readonly stockpile?: number
    readonly price?: Candle<number>;
}
