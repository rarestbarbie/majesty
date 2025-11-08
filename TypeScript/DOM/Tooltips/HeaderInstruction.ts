import { TooltipInstructionType } from '../exports.js';

export interface HeaderInstruction {
    readonly type: TooltipInstructionType.Header;

    readonly indent?: number;
    readonly html: string;
}
