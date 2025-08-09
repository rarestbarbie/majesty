import { CashAccount, FactoryWorkers } from "../exports.js";
import { GameDate } from "../../GameEngine/GameDate.js";
import { GameID } from "../../GameEngine/GameID.js";

export interface FactoryTableEntry {
    readonly id: GameID;
    readonly location: string;
    readonly type: string;
    readonly size: bigint;
    readonly grow: bigint;
    readonly cash: CashAccount;

    readonly y_vi: bigint;
    readonly y_vv: bigint;
    readonly y_wn: bigint;
    readonly y_wu: bigint;
    readonly y_cn: bigint;
    readonly y_cu: bigint;
    readonly y_ei: number;
    readonly y_eo: number;
    readonly y_fi: number;

    readonly t_vi: bigint;
    readonly t_vv: bigint;
    readonly t_wn: bigint;
    readonly t_wu: bigint;
    readonly t_cn: bigint;
    readonly t_cu: bigint;
    readonly t_ei: number;
    readonly t_eo: number;
    readonly t_fi: number;

    readonly workers: FactoryWorkers;
    readonly clerks: FactoryWorkers;
}
