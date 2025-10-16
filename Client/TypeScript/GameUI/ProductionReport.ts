import {
    FactoryDetails,
    FactoryTableEntry,
    LegalEntityFilterLabel,
    ScreenType
} from './exports.js';

export interface ProductionReport {
    readonly type: ScreenType.Production;
    readonly factories: FactoryTableEntry[];
    readonly factory?: FactoryDetails;

    readonly filter?: string;
    readonly filterlist?: number;
    readonly filterlists: LegalEntityFilterLabel[][];
}
