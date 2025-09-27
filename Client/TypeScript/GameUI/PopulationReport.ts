import {
    PopDetails,
    PopTableEntry,
    ScreenType
} from './exports.js';

export interface PopulationReport {
    readonly type: ScreenType.Population;
    readonly pops: PopTableEntry[];
    readonly pop?: PopDetails;
}
