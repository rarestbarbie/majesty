import { ColorReference } from '../../GameEngine/exports.js';

export interface TickRuleState {
    readonly id: number;
    readonly y: number;
    readonly text: string;
    readonly grid?: boolean;
    readonly label?: ColorReference;
}
