import {
    GameID
} from '../../GameEngine/exports.js';
import {
    PlanetDetailsTab
} from '../exports.js';

export interface PlanetReportRequest {
    subject?: string,
    details?: PlanetDetailsTab,
    filter?: GameID,
}
