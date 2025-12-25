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
    readonly column?: number;
    readonly pops: PopTableEntry[];
    readonly pop?: PopDetails;

    readonly sex?: string;
    readonly sexes: string[];

    readonly filter?: string;
    readonly filterlist: number;
    readonly filterlists: LegalEntityFilterLabel[][];
}
