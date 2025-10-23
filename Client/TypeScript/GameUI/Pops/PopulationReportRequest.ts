import {
    GameID
} from '../../GameEngine/exports.js';
import {
    PopDetailsTab
} from '../exports.js';

export interface PopulationReportRequest {
    subject?: GameID,
    details?: PopDetailsTab,
    filter?: string,
}
