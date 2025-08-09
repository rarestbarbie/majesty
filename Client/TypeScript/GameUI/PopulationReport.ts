import { PopDetails } from './Pops/PopDetails.js';
import { PopTableEntry } from './Pops/PopTableEntry.js';
import { ScreenType } from './ScreenType.js';

export interface PopulationReport {
    readonly type: ScreenType.Population;
    readonly pops: PopTableEntry[];
    readonly pop?: PopDetails;
}
