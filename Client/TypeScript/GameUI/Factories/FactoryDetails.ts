import { GameID } from '../../GameEngine/GameID.js';
import { FactoryInventory, FactoryOwnership } from '../exports.js';

export interface FactoryDetails {
    readonly id: GameID;
    readonly open: FactoryInventory | FactoryOwnership;
}
