import {
    GameID
} from '../../GameEngine/exports.js';
import {
    BuildingDetailsTab,
} from '../exports.js';

export interface InfrastructureReportRequest {
    subject?: GameID,
    details?: BuildingDetailsTab,
    detailsTier?: string,
    filter?: string,
}
