import { Fortune, Sign, TooltipInstructionType } from '../exports.js';

export interface FactorInstruction {
    readonly type: TooltipInstructionType.Factor;

    readonly fortune?: Fortune;
    readonly indent?: number;
    readonly label: string;
    readonly value: string;
    readonly sign?: Sign;
}
