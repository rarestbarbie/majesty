import {
    HeaderInstruction,
    TickerInstruction,
    FactorInstruction,
    CountInstruction,
} from '../exports.js';

export type TooltipInstruction =
    | HeaderInstruction
    | TickerInstruction
    | FactorInstruction
    | CountInstruction;
