import {
    ScreenType,
    LegalEntityFilterLabel,
    PlanetDetails,
    PlanetMapTileState
} from '../exports.js';

export interface PlanetReport {
    readonly type: ScreenType.Planet;
    readonly details?: PlanetDetails;
    readonly entries: PlanetMapTileState[];
    readonly filter?: string;
    readonly filterlist: number;
    readonly filterlists: LegalEntityFilterLabel[][];

    readonly name?: string;
}
