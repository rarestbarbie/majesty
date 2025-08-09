import { MarketInterval } from '../exports.js';

export interface MarketDetails {
    readonly id: string;
    readonly history: MarketInterval[];
    readonly min: number;
    readonly max: number;
}
