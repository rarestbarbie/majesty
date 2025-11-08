import { Fortune, Sign, TooltipInstructionType } from '../exports.js';

export interface TickerInstruction {
    readonly type: TooltipInstructionType.Ticker;

    readonly fortune?: Fortune;
    readonly indent?: number;
    readonly label: string;
    readonly value: string;
    readonly delta: string;
    readonly sign?: Sign;
}
