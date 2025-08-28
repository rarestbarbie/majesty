import { GameDate } from '../../GameEngine/GameDate.js';
import { Candle } from '../exports.js';

export interface CandlestickChartInterval {
    readonly id: GameDate;
    readonly c: Candle<number>;
    readonly v: bigint;
}
