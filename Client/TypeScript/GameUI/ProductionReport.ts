import { ScreenType } from './ScreenType.js';
import { FactoryDetails } from './Factories/FactoryDetails.js';
import { FactoryTableEntry } from './Factories/FactoryTableEntry.js';

export interface ProductionReport {
    readonly type: ScreenType.Production;
    readonly factories: FactoryTableEntry[];
    readonly factory?: FactoryDetails;
}
