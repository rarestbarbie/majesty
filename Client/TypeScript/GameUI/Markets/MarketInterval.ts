import { GameDate } from '../../GameEngine/GameDate.js';
import { Candle } from './Candle.js';

export interface MarketInterval {
    readonly id: GameDate;
    readonly c: Candle<number>;
}
