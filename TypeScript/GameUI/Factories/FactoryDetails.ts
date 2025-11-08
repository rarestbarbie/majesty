import { GameID } from '../../GameEngine/GameID.js';
import {
    FactoryDetailsTab,
    InventoryBreakdownState,
    OwnershipBreakdownState
} from '../exports.js';

export interface FactoryDetails {
    readonly id: GameID;
    readonly type?: string;
    readonly open:
        InventoryBreakdownState<FactoryDetailsTab.Inventory> |
        OwnershipBreakdownState<FactoryDetailsTab.Ownership>;
}
