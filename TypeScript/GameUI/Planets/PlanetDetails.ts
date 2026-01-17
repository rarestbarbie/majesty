import { TermState } from '../../DOM/exports.js';
import { GameID } from '../../GameEngine/exports.js';
import {
    PieChartSector,
    TimeSeriesState
} from '../exports.js';

export interface PlanetDetails {
    readonly id: string;
    readonly open: string;
    readonly name?: string;
    readonly terms: TermState[];
    readonly gdp?: PieChartSector<GameID>[];
    readonly gdpGraph: TimeSeriesState;
}
