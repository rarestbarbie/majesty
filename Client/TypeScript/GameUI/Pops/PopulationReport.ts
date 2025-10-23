import {
    TableColumnMetadata
} from '../../DOM/exports.js';
import {
    LegalEntityFilterLabel,
    PopDetails,
    PopTableEntry,
    ScreenType
} from '../exports.js';

export interface PopulationReport {
    readonly type: ScreenType.Population;

    readonly columns: TableColumnMetadata<string>[];
    readonly pops: PopTableEntry[];
    readonly pop?: PopDetails;

    readonly filter?: string;
    readonly filterlist?: number;
    readonly filterlists: LegalEntityFilterLabel[][];
}
