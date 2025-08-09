import { Color, GameID } from '../../GameEngine/exports.js';
import { CashAccount, PopJobDescription, PopType } from '../exports.js';

export interface PopTableEntry {
    readonly id: GameID;
    readonly location: string;
    readonly type: PopType;
    readonly color: Color;
    readonly nat: string;
    readonly une: number;

    readonly y_size: bigint;
    readonly y_mil: number;
    readonly y_con: number;
    readonly y_fl: number;
    readonly y_fe: number;
    readonly y_fx: number;

    readonly t_size: bigint;
    readonly t_mil: number;
    readonly t_con: number;
    readonly t_fl: number;
    readonly t_fe: number;
    readonly t_fx: number;

    readonly jobs: PopJobDescription[];
    readonly cash: CashAccount;
}
