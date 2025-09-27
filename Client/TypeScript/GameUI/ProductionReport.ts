import {
    FactoryDetails,
    FactoryTableEntry,
    ScreenType
} from './exports.js';

export interface ProductionReport {
    readonly type: ScreenType.Production;
    readonly factories: FactoryTableEntry[];
    readonly factory?: FactoryDetails;
}
