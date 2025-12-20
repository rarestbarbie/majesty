import {
    ContextMenuState,
    TooltipBreakdown,
    TooltipInstructions,
} from './DOM/exports.js';
import { GameID, GameDate, GameDateComponents } from './GameEngine/exports.js';
import {
    Application,
    CelestialViewState,
    ContextMenuType,
    FactoryDetailsTab,
    InfrastructureReportRequest,
    InfrastructureReport,
    MinimapLayer,
    NavigatorState,
    PlanetReportRequest,
    PlanetReport,
    PlanetTileEditorState,
    ProductionReportRequest,
    ProductionReport,
    PopulationReportRequest,
    PopulationReport,
    PopDetailsTab,
    TradeReportRequest,
    TradeReport,
    TooltipType,
    GameUI,
} from './GameUI/exports.js';
import { PlayerEvent } from './Multiplayer/exports.js';

export class Swift {
    // these are used by the WebAssembly to signal when API methods are ready
    readonly success: (value: void | PromiseLike<void>) => void;
    readonly failure: (reason?: any) => void;

    public readonly ready: Promise<void>;

    constructor() {
        let success: (value: void | PromiseLike<void>) => void;
        let failure: (reason?: any) => void;

        this.ready = new Promise<void>((resolve, reject) => {
            success = resolve;
            failure = reject;
        });

        this.success = success!;
        this.failure = failure!;
    }

    // Will be added by Swift WebAssembly
    declare public static bind: (ui: Application) => void;
    declare public static load: (
        state: Object,
        rules: Object,
        terrain: Object[]
    ) => Promise<GameUI | null>;
    declare public static call: (action: string, _: any[]) => void;
    declare public static push: (event: PlayerEvent, i: bigint) => void;

    declare public static orbit: (id: GameID) => Float32Array | null;
    declare public static gregorian: (date: GameDate) => GameDateComponents;

    declare public static openPlanet: (request: PlanetReportRequest) => PlanetReport;
    declare public static openInfrastructure: (request: InfrastructureReportRequest) => InfrastructureReport;
    declare public static openProduction: (request: ProductionReportRequest) => ProductionReport;
    declare public static openPopulation: (request: PopulationReportRequest) => PopulationReport;
    declare public static openTrade: (request: TradeReportRequest) => TradeReport;
    declare public static closeScreen: () => void;

    declare public static minimap: (
        planet: GameID,
        layer: MinimapLayer | null,
        cell: string | null
    ) => NavigatorState;
    declare public static view: (index: number, system: GameID) => Promise<CelestialViewState>;

    declare public static tooltip: (
        type: TooltipType,
        arguments: any[]
    ) => TooltipInstructions | TooltipBreakdown | null;

    declare public static contextMenu: (type: ContextMenuType, argumentList: any[]) => ContextMenuState;

    declare public static editTerrain: () => Promise<PlanetTileEditorState | null>;
    declare public static loadTerrain: (from: PlanetTileEditorState) => void;
    declare public static saveTerrain: () => any[] | null;
}
