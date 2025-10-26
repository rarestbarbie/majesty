import {
    PieChartSector,
    ResourceNeed,
    ResourceNeedMeterState,
    ResourceSale
} from '../exports.js';

export interface InventoryBreakdownState<Type extends string> {
    readonly type: Type;
    readonly tiers: ResourceNeedMeterState[];
    readonly needs: ResourceNeed[];
    readonly sales: ResourceSale[];
    readonly costs?: PieChartSector<string>[];
    readonly budget?: PieChartSector<string>[];
}
