import {
    GameID
} from '../../GameEngine/exports.js';
import {
    PlanetDetailsTab
} from '../exports.js';

export interface PlanetReportRequest {
    subject?: GameID,
    details?: PlanetDetailsTab,
    filter?: string,
}
