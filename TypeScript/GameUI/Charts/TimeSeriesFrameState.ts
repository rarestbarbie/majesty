import { GameDate } from '../../GameEngine/exports.js';

export interface TimeSeriesFrameState {
    readonly id: GameDate;
    readonly y: number;
}
