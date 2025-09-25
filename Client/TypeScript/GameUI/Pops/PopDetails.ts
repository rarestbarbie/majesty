import { GameID } from '../../GameEngine/GameID.js';
import {
    InventoryBreakdownState,
    OwnershipBreakdownState,
    PopDetailsTab
} from '../exports.js';

export interface PopDetails {
    readonly id: GameID;

    readonly type_singular?: string;
    readonly type_plural?: string;
    readonly type?: string;

    readonly open:
        InventoryBreakdownState<PopDetailsTab.Inventory> |
        OwnershipBreakdownState<PopDetailsTab.Ownership>;
}
