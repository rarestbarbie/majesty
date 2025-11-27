import { GameID } from "../../GameEngine/GameID.js";

export interface BuildingTableEntry {
    readonly id: GameID;
    readonly location: string;
    readonly type: string;
    readonly y_size: bigint;
    readonly z_size: bigint;
}
