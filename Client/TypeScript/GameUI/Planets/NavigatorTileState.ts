import { PieChartSector } from '../exports.js';

export interface NavigatorTileState {
    readonly id: string;
    readonly name: string;
    readonly terrain: string;
    readonly culture?: PieChartSector<string>[];
    readonly popType?: PieChartSector<string>[];
}
