import {
    InfrastructureReport,
    ProductionReport,
    PopulationReport,
    PlanetReport,
    TradeReport
} from './exports.js';

export type PersistentReport = InfrastructureReport
    | ProductionReport
    | PopulationReport
    | PlanetReport
    | TradeReport;
