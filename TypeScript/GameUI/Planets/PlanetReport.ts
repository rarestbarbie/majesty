import { ScreenType, PlanetDetails } from '../exports.js';

export interface PlanetReport {
    readonly type: ScreenType.Planet;
    readonly planet: PlanetDetails;
}
