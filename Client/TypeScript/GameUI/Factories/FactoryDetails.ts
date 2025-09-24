import { GameID } from '../../GameEngine/GameID.js';
import { FactoryDetailsTab, InventoryBreakdown, OwnershipBreakdown } from '../exports.js';

export interface FactoryDetails {
    readonly id: GameID;
    readonly open:
        InventoryBreakdown<FactoryDetailsTab.Inventory> |
        OwnershipBreakdown<FactoryDetailsTab.Ownership>;
}
