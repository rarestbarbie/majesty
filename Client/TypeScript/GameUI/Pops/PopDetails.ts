import { GameID } from '../../GameEngine/GameID.js';
import { ResourceNeed, ResourceSale, PieChartSector } from '../exports.js';

export interface PopDetails {
    readonly id: GameID;

    readonly type_singular?: string;
    readonly type_plural?: string;
    readonly type?: string;

    readonly needs: ResourceNeed[];
    readonly sales: ResourceSale[];
    readonly spending?: PieChartSector<string>[];
}
