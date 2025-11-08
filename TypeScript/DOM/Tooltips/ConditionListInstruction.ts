import { ConditionListItem, TooltipInstructionType } from '../exports.js';

export interface ConditionListInstruction {
    readonly type: TooltipInstructionType.ConditionList;
    readonly list: ConditionListItem[];
}
