import { TermState } from '../DOM/exports.js';
import {
    PieChartSectorState,
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
    readonly costs?: PieChartSectorState<string>[];
    readonly budget?: PieChartSectorState<string>[];
}
