import { FactoryWorkers } from '../exports.js';
import { GameID } from "../../GameEngine/GameID.js";

export interface FactoryTableEntry {
    readonly id: GameID;
    readonly location: string;
    readonly type: string;
    readonly size_l: bigint;
    readonly size_p: number;
    readonly liqf?: number;

    readonly y_wn: bigint;
    readonly y_cn: bigint;

    readonly y_ei: number;
    readonly y_eo: number;
    readonly y_fi: number;

    readonly y_px: number;

    readonly t_wn: bigint;
    readonly t_cn: bigint;

    readonly t_ei: number;
    readonly t_eo: number;
    readonly t_fi: number;

    readonly t_px: number;

    readonly workers?: FactoryWorkers;
    readonly clerks?: FactoryWorkers;
}
