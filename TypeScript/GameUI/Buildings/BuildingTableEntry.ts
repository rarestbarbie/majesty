import { GameID } from "../../GameEngine/GameID.js";

export interface BuildingTableEntry {
    readonly id: GameID;
    readonly location: string;
    readonly type: string;
    readonly progress: number;
    readonly y_active: bigint;
    readonly y_vacant: bigint;
    readonly z_active: bigint;
    readonly z_vacant: bigint;
}
