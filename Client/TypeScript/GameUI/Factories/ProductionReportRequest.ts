import {
    GameID
} from '../../GameEngine/exports.js';
import {
    FactoryDetailsTab
} from '../exports.js';

export interface ProductionReportRequest {
    subject?: GameID,
    details?: FactoryDetailsTab,
    filter?: string,
}
