import { GameID } from '../../GameEngine/GameID.js';
import { ResourceNeed, ResourceSale } from '../exports.js';

export interface PopDetails {
    readonly id: GameID;
    readonly needs: ResourceNeed[];
    readonly sales: ResourceSale[];
}
