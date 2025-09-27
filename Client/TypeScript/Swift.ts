import {
    ContextMenuItem,
    TooltipBreakdown,
    TooltipInstructions,
} from './DOM/exports.js';
import { GameID, GameDate, GameDateComponents } from './GameEngine/exports.js';
import {
    Application,
    CelestialViewState,
    ContextMenuType,
    FactoryDetailsTab,
    MinimapLayer,
    NavigatorState,
    PlanetDetailsTab,
    PlanetReport,
    PlanetTileEditorState,
    ProductionReport,
    PopulationReport,
    PopDetailsTab,
    TradeReport,
    TooltipType,
    GameUI
} from './GameUI/exports.js';
import { PlayerEvent } from './Multiplayer/exports.js';

export class Swift {
    // Will be added by Swift WebAssembly
    declare public static start: (ui: Application) => void;
    declare public static load: (
        state: Object,
        rules: Object,
        terrain: Object[]
    ) => GameUI | null;
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
    declare public static openPopulation: (
        id: GameID | null,
        details: PopDetailsTab | null
    ) => PopulationReport;
    declare public static openTrade: (
        market: string | null,
        filter: string | null
    ) => TradeReport;
    declare public static closeScreen: () => void;

    declare public static switch: (planet: GameID) => GameUI;

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

    public static contextMenu(type: ContextMenuType, argumentList: any[]): ContextMenuItem[] {
        // In a real implementation, you would call the declared swift_context_menu function.
        // For now, we return a stubbed, hierarchical menu.
        console.log(`Requesting context menu of type '${type}' with arguments:`, argumentList);

        // Stubbed data
        return [
            {
                label: "Switch To Player",
                action: "switchToPlayer",
                arguments: ["player-uuid-12345"]
            },
            {
                label: "Diplomacy",
                submenu: [
                    { label: "Declare War", action: "declareWar", arguments: ["player-uuid-12345"] },
                    { label: "Offer Alliance", action: "offerAlliance", arguments: ["player-uuid-12345"], disabled: true },
                    {
                        label: "Trade Actions",
                        submenu: [
                            { label: "Open Trade Route", action: "openTradeRoute", arguments: ["player-uuid-12345"] },
                            { label: "View Trade History", action: "viewTradeHistory", arguments: ["player-uuid-12345"] },
                        ]
                    }
                ]
            },
            {
                label: "Inspect Tile",
                action: "InspectTile",
                arguments: argumentList
            }
        ];
    }

    public static call(action: string, argumentList: any[]): void {
        // This would eventually call a generic swift function to perform an action.
        console.log(`Swift.call -> Action: ${action}`, 'Args:', argumentList);
    }

    declare public static editTerrain: () => PlanetTileEditorState | null;
    declare public static loadTerrain: (from: PlanetTileEditorState) => void;
    declare public static saveTerrain: () => any[] | null;
}
