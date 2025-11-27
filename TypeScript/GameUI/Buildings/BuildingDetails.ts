import { GameID } from '../../GameEngine/GameID.js';
import {
    BuildingDetailsTab,
    InventoryBreakdownState,
    OwnershipBreakdownState
} from '../exports.js';

export interface BuildingDetails {
    readonly id: GameID;
    readonly type?: string;
    readonly open:
        InventoryBreakdownState<BuildingDetailsTab.Inventory> |
        OwnershipBreakdownState<BuildingDetailsTab.Ownership>;
}
