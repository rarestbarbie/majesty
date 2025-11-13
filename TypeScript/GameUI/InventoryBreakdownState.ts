import { TermState } from '../DOM/exports.js';
import {
    PieChartSector,
    ResourceNeed,
    ResourceNeedMeterState,
    ResourceSale
} from './exports.js';

export interface InventoryBreakdownState<Type extends string> {
    readonly type: Type;
    readonly focus: string;
    readonly tiers: ResourceNeedMeterState[];
    readonly needs: ResourceNeed[];
    readonly sales: ResourceSale[];
    readonly terms: TermState[];
    readonly costs?: PieChartSector<string>[];
    readonly budget?: PieChartSector<string>[];
}
