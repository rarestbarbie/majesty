import {
    PieChartSector,
    ResourceNeed,
    ResourceSale
} from '../exports.js';

export interface InventoryBreakdownState<Type extends string> {
    readonly type: Type;
    readonly needs: ResourceNeed[];
    readonly sales: ResourceSale[];
    readonly costs?: PieChartSector<string>[];
    readonly budget?: PieChartSector<string>[];
}
