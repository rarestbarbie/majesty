import GameIDs
import GameRules
import GameTerrain
import GameUI
import HexGrids
import JavaScriptInterop
import JavaScriptKit

public struct GameSession: ~Copyable {
    private var state: State
    private var ui: GameUI

    private init(state: consuming State, ui: consuming GameUI) {
        self.state = state
        self.ui = ui
    }

    private init(context: GameContext, world: consuming GameWorld) {
        self.init(state: .init(context: context, world: world), ui: .init())
    }
}
extension GameSession {
    public static func load(
        _ save: consuming GameSave,
        rules: borrowing GameRules,
        map: borrowing TerrainMap,
    ) throws -> Self {
        let metadata: GameMetadata = try rules.resolve(symbols: &save.symbols)
        return try .load(save, rules: metadata, map: map)
    }
    public static func load(
        start: consuming GameStart,
        rules: borrowing GameRules,
        map: borrowing TerrainMap,
    ) throws -> Self {
        var metadata: GameMetadata = try rules.resolve(symbols: &start.symbols)
        let save: GameSave = try start.unpack(rules: &metadata)
        return try .load(save, rules: metadata, map: map)
    }

    private static func load(
        _ save: borrowing GameSave,
        rules: consuming GameMetadata,
        map: borrowing TerrainMap,
    ) throws -> Self {
        .init(state: try .load(save, rules: rules, map: map), ui: .init())
    }

    public var save: GameSave { self.state.save }
}
extension GameSession {
    public mutating func loadTerrain(from editor: PlanetTileEditor) throws {
        try self.state.context.loadTerrain(from: editor)
    }

    public func editTerrain() -> PlanetTileEditor? {
        guard
        case (_, let current?) = self.ui.navigator.current,
        let planet: PlanetContext = self.state.context.planets[current.planet],
        let tile: PlanetGrid.Tile = planet.grid.tiles[current.tile] else {
            return nil
        }

        return .init(
            id: tile.id,
            rotate: nil,
            size: planet.grid.size,
            name: tile.name,
            terrain: tile.terrain.symbol,
            terrainChoices: self.state.context.rules.terrains.values.map(\.symbol),
            geology: tile.geology.symbol,
            geologyChoices: self.state.context.rules.geology.values.map(\.symbol)
        )
    }

    public func saveTerrain() -> TerrainMap { self.state.context.saveTerrain() }
}
extension GameSession {
    public mutating func faster() {
        self.ui.clock.faster()
    }
    public mutating func slower() {
        self.ui.clock.slower()
    }
    public mutating func pause() {
        self.ui.clock.pause()
    }

    public mutating func start() throws -> GameUI {
        try self.state.sync()
        try self.ui.sync(with: self.state)
        return self.ui
    }

    public mutating func tick() throws -> GameUI {
        if  self.ui.clock.tick() {
            try self.state.tick()
        }

        try self.ui.sync(with: self.state)
        return self.ui
    }

    public mutating func open(_ screen: GameUI.ScreenType?) {
        self.ui.screen = screen
    }
}
extension GameSession {
    public mutating func openPlanet(_ request: PlanetReportRequest) throws -> PlanetReport {
        self.ui.screen = .Planet
        self.ui.report.planet.select(request: request)
        self.ui.report.planet.update(from: self.state.snapshot)
        return self.ui.report.planet
    }

    public mutating func openInfrastructure(
        _ request: InfrastructureReportRequest
    ) throws -> InfrastructureReport {
        self.ui.screen = .Infrastructure
        self.ui.report.infrastructure.select(request: request)
        self.ui.report.infrastructure.update(from: self.state.snapshot, buildings: self.state.context.buildings)
        return self.ui.report.infrastructure
    }

    public mutating func openProduction(
        _ request: ProductionReportRequest
    ) throws -> ProductionReport {
        self.ui.screen = .Production
        self.ui.report.production.select(request: request)
        self.ui.report.production.update(from: self.state.snapshot, factories: self.state.context.factories)
        return self.ui.report.production
    }

    public mutating func openPopulation(
        _ request: PopulationReportRequest
    ) throws -> PopulationReport {
        self.ui.screen = .Population
        self.ui.report.population.select(request: request)
        self.ui.report.population.update(from: self.state.snapshot, pops: self.state.context.pops, mines: self.state.context.mines)
        return self.ui.report.population
    }

    public mutating func openTrade(_ request: TradeReportRequest) throws -> TradeReport {
        self.ui.screen = .Trade
        self.ui.report.trade.select(request: request)
        self.ui.report.trade.update(from: self.state.snapshot)
        return self.ui.report.trade
    }

    public mutating func minimap(
        planet: PlanetID,
        layer: MinimapLayer?,
        cell: HexCoordinate?
    ) -> Navigator {
        self.ui.navigator.select(planet: planet, layer: layer, cell: cell)
        self.ui.navigator.update(in: self.state.snapshot, planets: self.state.context.planets)
        return self.ui.navigator
    }

    public mutating func view(_ index: Int, to system: PlanetID) throws -> CelestialView {
        let view: CelestialView = try .open(subject: system, in: self.state.snapshot)
        switch index as Int {
        case 0: self.ui.views.0 = view
        case 1: self.ui.views.1 = view
        default: break
        }
        return view
    }

    public func orbit(_ id: PlanetID) -> JSTypedArray<Float>? {
        self.state.context.planets[id]?.motion.global?.rendered()
    }
}
extension GameSession {
    public mutating func call(
        _ action: ContextMenuAction,
        with arguments: borrowing JavaScriptDecoder<JavaScriptArrayKey>
    ) throws {
        switch action {
        case .SwitchToPlayer:
            self.callSwitchToPlayer(
                try arguments[0].decode(),
            )
        }
    }

    private mutating func callSwitchToPlayer(
        _ id: CountryID
    ) {
        self.state.context.player = id
    }
}
extension GameSession {
    private var cache: GameUI.Cache {
        var cache: GameUI.Cache = .init(
            game: self.state.snapshot,
            tiles: self.ui.navigator.minimap?.tiles ?? [:]
        )

        switch self.ui.screen {
        case .Production?:
            cache.factories = self.ui.report.production.factories

        case .Infrastructure?:
            cache.buildings = self.ui.report.infrastructure.buildings

        case .Population?:
            cache.pops = self.ui.report.population.pops

        case .Trade?:
            break

        case .Planet?:
            break

        case nil:
            break
        }

        return cache
    }
}
extension GameSession {
    private func contextMenuMinimapTile(
        _ id: PlanetID,
        _ cell: HexCoordinate,
        _ layer: MinimapLayer,
    ) -> ContextMenu? {
        guard
        let planet: PlanetContext = self.state.context.planets[id],
        let tile: PlanetGrid.Tile = planet.grid.tiles[cell] else {
            return nil
        }

        return .items {
            $0["Switch to Player"] {
                if  let country: CountryID = tile.authority?.governedBy {
                    $0[.SwitchToPlayer] = country
                }
            }
        }
    }

    public func contextMenu(
        type: ContextMenuType,
        with arguments: borrowing JavaScriptDecoder<JavaScriptArrayKey>
    ) throws -> ContextMenu? {
        switch type {
        case .MinimapTile:
            self.contextMenuMinimapTile(
                try arguments[0].decode(),
                try arguments[1].decode(),
                try arguments[2].decode(),
            )
        }
    }

    public func tooltip(
        type: TooltipType,
        with arguments: borrowing JavaScriptDecoder<JavaScriptArrayKey>
    ) throws -> Tooltip? {
        switch type {
        case .BuildingAccount:
            return self.cache.tooltipBuildingAccount(
                try arguments[0].decode(),
            )
        case .BuildingActive:
            return self.cache.tooltipBuildingActive(
                try arguments[0].decode(),
            )
        case .BuildingActiveHelp:
            return self.cache.tooltipBuildingActiveHelp(
                try arguments[0].decode(),
            )
        case .BuildingVacant:
            return self.cache.tooltipBuildingVacant(
                try arguments[0].decode(),
            )
        case .BuildingVacantHelp:
            return self.cache.tooltipBuildingVacantHelp(
                try arguments[0].decode(),
            )
        case .BuildingNeeds:
            return self.cache.tooltipBuildingNeeds(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .BuildingResourceIO:
            return self.cache.tooltipBuildingResourceIO(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .BuildingStockpile:
            return self.cache.tooltipBuildingStockpile(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .BuildingExplainPrice:
            return self.cache.tooltipBuildingExplainPrice(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .BuildingOwnershipCountry:
            return self.cache.tooltipBuildingOwnership(
                try arguments[0].decode(),
                country: try arguments[1].decode(),
            )
        case .BuildingOwnershipCulture:
            return self.cache.tooltipBuildingOwnership(
                try arguments[0].decode(),
                culture: try arguments[1].decode(),
            )
        case .BuildingOwnershipSecurities:
            return self.cache.tooltipBuildingOwnership(
                try arguments[0].decode(),
            )
        case .BuildingCashFlowItem:
            return self.cache.tooltipBuildingCashFlowItem(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .BuildingBudgetItem:
            return self.cache.tooltipBuildingBudgetItem(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .FactoryAccount:
            return self.cache.tooltipFactoryAccount(
                try arguments[0].decode(),
            )
        case .FactoryClerks:
            return self.cache.tooltipFactoryClerks(
                try arguments[0].decode(),
            )
        case .FactoryClerksHelp:
            return self.cache.tooltipFactoryClerksHelp(
                try arguments[0].decode(),
            )
        case .FactoryWorkers:
            return self.cache.tooltipFactoryWorkers(
                try arguments[0].decode(),
            )
        case .FactoryWorkersHelp:
            return self.cache.tooltipFactoryWorkersHelp(
                try arguments[0].decode(),
            )
        case .FactorySize:
            return self.cache.tooltipFactorySize(
                try arguments[0].decode(),
            )
        case .FactoryNeeds:
            return self.cache.tooltipFactoryNeeds(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .FactoryResourceIO:
            return self.cache.tooltipFactoryResourceIO(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .FactoryStockpile:
            return self.cache.tooltipFactoryStockpile(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .FactoryExplainPrice:
            return self.cache.tooltipFactoryExplainPrice(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .FactorySummarizeEmployees:
            return self.cache.tooltipFactorySummarizeEmployees(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .FactoryOwnershipCountry:
            return self.cache.tooltipFactoryOwnership(
                try arguments[0].decode(),
                country: try arguments[1].decode(),
            )
        case .FactoryOwnershipCulture:
            return self.cache.tooltipFactoryOwnership(
                try arguments[0].decode(),
                culture: try arguments[1].decode(),
            )
        case .FactoryOwnershipSecurities:
            return self.cache.tooltipFactoryOwnership(
                try arguments[0].decode(),
            )
        case .FactoryCashFlowItem:
            return self.cache.tooltipFactoryCashFlowItem(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .FactoryBudgetItem:
            return self.cache.tooltipFactoryBudgetItem(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .PopAccount:
            return self.cache.tooltipPopAccount(
                try arguments[0].decode(),
            )
        case .PopActive:
            return self.cache.tooltipPopActive(
                try arguments[0].decode(),
            )
        case .PopActiveHelp:
            return self.cache.tooltipPopActiveHelp(
                try arguments[0].decode(),
            )
        case .PopVacant:
            return self.cache.tooltipPopVacant(
                try arguments[0].decode(),
            )
        case .PopVacantHelp:
            return self.cache.tooltipPopVacantHelp(
                try arguments[0].decode(),
            )
        case .PopJobs:
            return self.cache.tooltipPopJobs(
                try arguments[0].decode(),
            )
        case .PopResourceIO:
            return self.cache.tooltipPopResourceIO(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .PopResourceOrigin:
            return self.cache.tooltipPopResourceOrigin(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .PopStockpile:
            return self.cache.tooltipPopStockpile(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .PopExplainPrice:
            return self.cache.tooltipPopExplainPrice(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .PopNeeds:
            return self.cache.tooltipPopNeeds(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .PopType:
            return self.cache.tooltipPopType(
                try arguments[0].decode(),
            )
        case .PopOwnershipCountry:
            return self.cache.tooltipPopOwnership(
                try arguments[0].decode(),
                country: try arguments[1].decode(),
            )
        case .PopOwnershipCulture:
            return self.cache.tooltipPopOwnership(
                try arguments[0].decode(),
                culture: try arguments[1].decode(),
            )
        case .PopOwnershipSecurities:
            return self.cache.tooltipPopOwnership(
                try arguments[0].decode(),
            )
        case .PopCashFlowItem:
            return self.cache.tooltipPopCashFlowItem(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .PopBudgetItem:
            return self.cache.tooltipPopBudgetItem(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .MarketLiquidity:
            return self.cache.tooltipMarketLiquidity(
                try arguments[0].decode(),
            )
        case .PlanetCell:
            return self.cache.tooltipPlanetCell(
                try arguments[0].decode(),
                try arguments[1].decode(),
                try arguments[2].decode(),
            )
        case .TileCulture:
            return self.cache.tooltipTileCulture(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .TilePopType:
            return self.cache.tooltipTilePopType(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        }
    }
}

#if TESTABLE
extension GameSession {
    public mutating func run(until date: GameDate) throws {
        try self.state.run(until: date)
    }

    public var _hash: Int {
        self.state._hash
    }

    public static func != (a: borrowing Self, b: borrowing Self) -> Bool {
        a.state != b.state
    }

    public var rules: GameMetadata { self.state.context.rules }
}
#endif
