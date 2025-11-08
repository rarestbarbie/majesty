import { Fortune, Sign, TooltipInstructionType } from '../exports.js';

export interface CountInstruction {
    readonly type: TooltipInstructionType.Count;

    readonly fortune?: Fortune;
    readonly indent?: number;
    readonly label: string;
    readonly value: string;
    readonly limit: string;
    readonly sign?: Sign;
}
