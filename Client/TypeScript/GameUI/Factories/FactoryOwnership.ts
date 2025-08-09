import { FactoryDetailsTab, PieChartSector } from '../exports.js';
import { GameID } from '../../GameEngine/exports.js';

export interface FactoryOwnership {
    readonly type: FactoryDetailsTab.Ownership;
    readonly culture?: PieChartSector<string>[];
    readonly country?: PieChartSector<GameID>[];
}
