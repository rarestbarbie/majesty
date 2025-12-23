import { GameID } from '../../GameEngine/GameID.js';
import {
    InventoryBreakdownState,
    OwnershipBreakdownState,
    PopDetailsTab
} from '../exports.js';

export interface PopDetails {
    readonly id: GameID;

    readonly occupation_singular?: string;
    readonly occupation_plural?: string;
    readonly occupation?: string;
    readonly gender?: string;
    readonly cis?: boolean;

    readonly open:
        InventoryBreakdownState<PopDetailsTab.Inventory> |
        OwnershipBreakdownState<PopDetailsTab.Ownership>;
}
