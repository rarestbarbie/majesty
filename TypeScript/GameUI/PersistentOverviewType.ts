import { ScreenType, TooltipType } from './exports.js';

export interface PersistentOverviewType {
    readonly screen: ScreenType;
    readonly tooltipCashFlowItem: TooltipType;
    readonly tooltipBudgetItem: TooltipType;
    readonly tooltipExplainPrice: TooltipType;
    readonly tooltipResourceOrigin?: TooltipType;
    readonly tooltipResourceIO: TooltipType;
    readonly tooltipStockpile: TooltipType;
}
