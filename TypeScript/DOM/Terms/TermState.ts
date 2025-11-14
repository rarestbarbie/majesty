import {
    TooltipInstruction,
} from '../exports.js';

export interface TermState {
    readonly id: string;
    readonly details: TooltipInstruction;
    readonly tooltip?: string;
}
