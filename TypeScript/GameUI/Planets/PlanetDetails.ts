import { TermState } from '../../DOM/exports.js';
import {
    PieChartSectorState,
    TimeSeriesState
} from '../exports.js';

export interface PlanetDetails {
    readonly id: string;
    readonly open: string;
    readonly name?: string;
    readonly terms: TermState[];
    readonly produced?: PieChartSectorState<number>[];
    readonly consumed?: PieChartSectorState<number>[];
    readonly gdp?: PieChartSectorState<string>[];
    readonly gdpGraph: TimeSeriesState;
}
