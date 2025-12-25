import {
    BuildingDetails,
    BuildingTableEntry,
    LegalEntityFilterLabel,
    ScreenType
} from '../exports.js';

export interface InfrastructureReport {
    readonly type: ScreenType.Infrastructure;
    readonly buildings: BuildingTableEntry[];
    readonly building?: BuildingDetails;

    readonly filter?: string;
    readonly filterlist: number;
    readonly filterlists: LegalEntityFilterLabel[][];
}
