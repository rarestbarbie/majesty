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
    InfrastructureReportRequest,
    InfrastructureReport,
    NavigatorState,
    PlanetReportRequest,
    PlanetReport,
    PlanetTileEditorState,
    ProductionReportRequest,
    ProductionReport,
    PopulationReportRequest,
    PopulationReport,
    TradeReportRequest,
    TradeReport,
    TooltipType,
    GameUI,
} from './GameUI/exports.js';
import { PlayerEvent, PlayerEventID } from './Multiplayer/exports.js';

export class Swift {
    private readonly application: Application
    private master: boolean;

    // these are used by the WebAssembly to signal when API methods are ready
    readonly success: (value: void | PromiseLike<void>) => void;
    readonly failure: (reason?: any) => void;

    public readonly ready: Promise<void>;

    constructor(application: Application) {
        this.application = application;
        this.master = false;

        let success: (value: void | PromiseLike<void>) => void;
        let failure: (reason?: any) => void;

        this.ready = new Promise<void>((resolve, reject) => {
            success = resolve;
            failure = reject;
        });

        this.success = success!;
        this.failure = failure!;
    }

    public loaded(): void {
        this.application.view(0, 10 as GameID);
        this.application.navigate();
        this.application.resize();
    }

    public start(): void {
        this.master = true;
        Application.move({ id: PlayerEventID.Tick });
    }

    public tick(): void {
        if (!this.master) {
            return;
        }

        Application.move({ id: PlayerEventID.Tick });
    }

    public draw(ui: GameUI): void {
        this.application.update(ui);
    }

    // Will be added by Swift WebAssembly
    declare public static load: (
        state: Object,
        rules: Object,
        terrain: Object[]
    ) => Promise<boolean>;
    declare public static call: (action: string, _: any[]) => void;
    declare public static push: (event: PlayerEvent, i: bigint) => void;

    declare public static orbit: (id: GameID) => Float32Array | null;
    declare public static gregorian: (date: GameDate) => GameDateComponents;

    declare public static openPlanet: (
        request: PlanetReportRequest
    ) => Promise<PlanetReport>;
    declare public static openInfrastructure: (
        request: InfrastructureReportRequest
    ) => Promise<InfrastructureReport>;
    declare public static openProduction: (
        request: ProductionReportRequest
    ) => Promise<ProductionReport>;
    declare public static openPopulation: (
        request: PopulationReportRequest
    ) => Promise<PopulationReport>;
    declare public static openTrade: (
        request: TradeReportRequest
    ) => Promise<TradeReport>;
    declare public static closeScreen: () => Promise<void>;

    declare public static minimapTile: (id: string) => Promise<NavigatorState>;
    declare public static minimap: (
        planet: GameID,
        layer: string | null,
    ) => Promise<NavigatorState>;
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
