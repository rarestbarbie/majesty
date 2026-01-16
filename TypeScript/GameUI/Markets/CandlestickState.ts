import { GameDate } from '../../GameEngine/exports.js';
import { Candle } from '../exports.js';

export interface CandlestickState {
    readonly id: GameDate;
    readonly c: Candle<number>;
    readonly v: bigint;
}
