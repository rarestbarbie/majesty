import {
    TooltipBreakdown,
    TooltipInstructions,
} from './DOM/exports.js';
import { GameID, GameDate, GameDateComponents } from './GameEngine/exports.js';
import {
    CelestialViewState,
    MinimapLayer,
    NavigatorState,
    PlanetDetailsTab,
    PlanetReport,
    PlanetTileEditorState,
    ProductionReport,
    PopulationReport,
    TradeReport,
    FactoryDetailsTab,
    TooltipType,
} from './GameUI/exports.js';
import { PlayerEvent } from './Multiplayer/exports.js';

export class Swift {
    // Will be added by Swift WebAssembly
    declare public static load: (state: Object, rules: Object, terrain: Object[]) => boolean;
    declare public static push: (event: PlayerEvent, i: bigint) => void;

    declare public static orbit: (id: GameID) => Float32Array | null;
    declare public static gregorian: (date: GameDate) => GameDateComponents;

    declare public static openPlanet: (
        planet: GameID | null,
        details: PlanetDetailsTab | null,
    ) => PlanetReport;
    declare public static openProduction: (
        factory: GameID | null,
        details: FactoryDetailsTab | null,
    ) => ProductionReport;
    declare public static openPopulation: (id: GameID | null) => PopulationReport;
    declare public static openTrade: (
        market: string | null,
        filter: string | null
    ) => TradeReport;
    declare public static closeScreen: () => void;

    declare public static switch: (planet: GameID) => void;

    declare public static minimap: (
        planet: GameID,
        layer: MinimapLayer | null,
        cell: string | null
    ) => NavigatorState;
    declare public static view: (index: number, system: GameID) => CelestialViewState;

    declare public static tooltip: (
        type: TooltipType,
        arguments: any[]
    ) => TooltipInstructions | TooltipBreakdown | null;

    declare public static editTerrain: () => PlanetTileEditorState | null;
    declare public static loadTerrain: (from: PlanetTileEditorState) => void;
    declare public static saveTerrain: () => any[] | null;
}
