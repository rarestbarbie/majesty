import { GameID } from '../../GameEngine/GameID.js';
import { ResourceNeed, ResourceSale, PieChartSector } from '../exports.js';

export interface PopDetails {
    readonly id: GameID;
    readonly needs: ResourceNeed[];
    readonly sales: ResourceSale[];
    readonly spending?: PieChartSector<string>[];
}
