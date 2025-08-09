import { GameDate } from '../GameEngine/exports.js';
import { Country, Navigator, PersistentReport, CelestialViewState } from './exports.js';

export interface GameUI {
    readonly speed: {
        readonly paused: boolean;
        readonly ticks: number;
    };
    readonly date: GameDate;
    readonly views: (CelestialViewState | null)[];
    readonly player?: Country;

    readonly navigator: Navigator;
    readonly screen?: PersistentReport;
}
