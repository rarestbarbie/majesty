import GameIDs
import GameRules
import GameTerrain
import GameUI
import HexGrids
import JavaScriptInterop
import JavaScriptKit

import Synchronization

public actor GameSession {
    private var state: State
    private var ui: GameUI

    private let cache: Mutex<GameUI.Cache?>

    private init(state: consuming State, ui: consuming GameUI) {
        self.state = state
        self.ui = ui

        self.cache = .init(nil)
    }

    private init(context: GameContext, world: consuming GameWorld) {
        self.init(state: .init(context: context, world: world), ui: .init())
    }
}
extension GameSession {
    private func publish() throws {
        try self.ui.sync(with: self.state)

        let context: GameUI.CacheContext = .init(
            currencies: self.state.context.currencies,
            countries: self.state.context.countries.state.reduce(into: [:]) { $0[$1.id] = $1 },
            markets: self.state.snapshot.markets,
            orbits: self.state.context.planets.reduce(into: [:]) {
                $0[$1.state.id] = $1.motion.global
            },
            bank: self.state.snapshot.bank,
            rules: self.state.snapshot.rules
        )

        self.cache.withLock {
            var cache: GameUI.Cache = .init(
                context: context,
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
            $0 = consume cache
        }
    }
}
extension GameSession {
    public static nonisolated func load(
        _ save: consuming GameSave,
        rules: borrowing GameRules,
        map: borrowing TerrainMap,
    ) throws -> Self {
        let metadata: GameMetadata = try rules.resolve(symbols: &save.symbols)
        return try .load(save, rules: metadata, map: map)
    }
    public static nonisolated func load(
        start: consuming GameStart,
        rules: borrowing GameRules,
        map: borrowing TerrainMap,
    ) throws -> Self {
        var metadata: GameMetadata = try rules.resolve(symbols: &start.symbols)
        let save: GameSave = try start.unpack(rules: &metadata)
        return try .load(save, rules: metadata, map: map)
    }

    private static nonisolated func load(
        _ save: sending GameSave,
        rules: consuming sending GameMetadata,
        map: borrowing TerrainMap,
    ) throws -> Self {
        .init(state: try .load(save, rules: rules, map: map), ui: .init())
    }

    public var save: GameSave { self.state.save }
}
extension GameSession {
    public func loadTerrain(from editor: PlanetTileEditor) throws {
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
    public func faster() {
        self.ui.clock.faster()
    }
    public func slower() {
        self.ui.clock.slower()
    }
    public func pause() {
        self.ui.clock.pause()
    }

    public func start() throws -> GameUI {
        try self.state.sync()
        try self.publish()
        return self.ui
    }

    public func tick() throws -> GameUI {
        if  self.ui.clock.tick() {
            try self.state.tick()
        }

        try self.publish()
        return self.ui
    }

    public func open(_ screen: GameUI.ScreenType?) {
        self.ui.screen = screen
    }
}
extension GameSession {
    public func openPlanet(_ request: PlanetReportRequest) throws -> PlanetReport {
        self.ui.screen = .Planet
        self.ui.report.planet.select(request: request)
        self.ui.report.planet.update(from: self.state.snapshot)
        return self.ui.report.planet
    }

    public func openInfrastructure(
        _ request: InfrastructureReportRequest
    ) throws -> InfrastructureReport {
        self.ui.screen = .Infrastructure
        self.ui.report.infrastructure.select(request: request)
        self.ui.report.infrastructure.update(from: self.state.snapshot, buildings: self.state.context.buildings)
        return self.ui.report.infrastructure
    }

    public func openProduction(
        _ request: ProductionReportRequest
    ) throws -> ProductionReport {
        self.ui.screen = .Production
        self.ui.report.production.select(request: request)
        self.ui.report.production.update(from: self.state.snapshot, factories: self.state.context.factories)
        return self.ui.report.production
    }

    public func openPopulation(
        _ request: PopulationReportRequest
    ) throws -> PopulationReport {
        self.ui.screen = .Population
        self.ui.report.population.select(request: request)
        self.ui.report.population.update(from: self.state.snapshot, pops: self.state.context.pops, mines: self.state.context.mines)
        return self.ui.report.population
    }

    public func openTrade(_ request: TradeReportRequest) throws -> TradeReport {
        self.ui.screen = .Trade
        self.ui.report.trade.select(request: request)
        self.ui.report.trade.update(from: self.state.snapshot)
        return self.ui.report.trade
    }

    public func minimap(
        planet: PlanetID,
        layer: MinimapLayer?,
        cell: HexCoordinate?
    ) -> Navigator {
        self.ui.navigator.select(planet: planet, layer: layer, cell: cell)
        self.ui.navigator.update(in: self.state.snapshot, planets: self.state.context.planets)
        return self.ui.navigator
    }

    public func view(_ index: Int, to system: PlanetID) throws -> CelestialView {
        let view: CelestialView = try .open(subject: system, in: self.state.snapshot)
        switch index as Int {
        case 0: self.ui.views.0 = view
        case 1: self.ui.views.1 = view
        default: break
        }
        return view
    }
}
extension GameSession {
    public nonisolated func call(
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

    private nonisolated func callSwitchToPlayer(
        _ id: CountryID
    ) {
        let _: Task<Void, Never> = .init {
            await { (self: isolated GameSession) in self.state.context.player = id } (self)
        }
    }
}
extension GameSession {
    public nonisolated func contextMenu(
        type: ContextMenuType,
        with arguments: borrowing JavaScriptDecoder<JavaScriptArrayKey>
    ) throws -> ContextMenu? {
        try self.cache.withLock {
            switch type {
            case .MinimapTile:
                return $0?.contextMenuMinimapTile(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                    try arguments[2].decode(),
                )
            }
        }
    }

    public nonisolated func orbit(_ id: PlanetID) -> JSTypedArray<Float>? {
        self.cache.withLock {
            $0?.orbits[id]?.rendered()
        }
    }

    public nonisolated func tooltip(
        type: TooltipType,
        with arguments: borrowing JavaScriptDecoder<JavaScriptArrayKey>
    ) throws -> Tooltip? {
        try self.cache.withLock {
            switch type {
            case .BuildingAccount:
                return $0?.tooltipBuildingAccount(
                    try arguments[0].decode(),
                )
            case .BuildingActive:
                return $0?.tooltipBuildingActive(
                    try arguments[0].decode(),
                )
            case .BuildingActiveHelp:
                return $0?.tooltipBuildingActiveHelp(
                    try arguments[0].decode(),
                )
            case .BuildingVacant:
                return $0?.tooltipBuildingVacant(
                    try arguments[0].decode(),
                )
            case .BuildingVacantHelp:
                return $0?.tooltipBuildingVacantHelp(
                    try arguments[0].decode(),
                )
            case .BuildingNeeds:
                return $0?.tooltipBuildingNeeds(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .BuildingResourceIO:
                return $0?.tooltipBuildingResourceIO(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .BuildingStockpile:
                return $0?.tooltipBuildingStockpile(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .BuildingExplainPrice:
                return $0?.tooltipBuildingExplainPrice(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .BuildingOwnershipCountry:
                return $0?.tooltipBuildingOwnership(
                    try arguments[0].decode(),
                    country: try arguments[1].decode(),
                )
            case .BuildingOwnershipCulture:
                return $0?.tooltipBuildingOwnership(
                    try arguments[0].decode(),
                    culture: try arguments[1].decode(),
                )
            case .BuildingOwnershipSecurities:
                return $0?.tooltipBuildingOwnership(
                    try arguments[0].decode(),
                )
            case .BuildingCashFlowItem:
                return $0?.tooltipBuildingCashFlowItem(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .BuildingBudgetItem:
                return $0?.tooltipBuildingBudgetItem(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .FactoryAccount:
                return $0?.tooltipFactoryAccount(
                    try arguments[0].decode(),
                )
            case .FactoryClerks:
                return $0?.tooltipFactoryClerks(
                    try arguments[0].decode(),
                )
            case .FactoryClerksHelp:
                return $0?.tooltipFactoryClerksHelp(
                    try arguments[0].decode(),
                )
            case .FactoryWorkers:
                return $0?.tooltipFactoryWorkers(
                    try arguments[0].decode(),
                )
            case .FactoryWorkersHelp:
                return $0?.tooltipFactoryWorkersHelp(
                    try arguments[0].decode(),
                )
            case .FactorySize:
                return $0?.tooltipFactorySize(
                    try arguments[0].decode(),
                )
            case .FactoryNeeds:
                return $0?.tooltipFactoryNeeds(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .FactoryResourceIO:
                return $0?.tooltipFactoryResourceIO(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .FactoryStockpile:
                return $0?.tooltipFactoryStockpile(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .FactoryExplainPrice:
                return $0?.tooltipFactoryExplainPrice(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .FactorySummarizeEmployees:
                return $0?.tooltipFactorySummarizeEmployees(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .FactoryOwnershipCountry:
                return $0?.tooltipFactoryOwnership(
                    try arguments[0].decode(),
                    country: try arguments[1].decode(),
                )
            case .FactoryOwnershipCulture:
                return $0?.tooltipFactoryOwnership(
                    try arguments[0].decode(),
                    culture: try arguments[1].decode(),
                )
            case .FactoryOwnershipSecurities:
                return $0?.tooltipFactoryOwnership(
                    try arguments[0].decode(),
                )
            case .FactoryCashFlowItem:
                return $0?.tooltipFactoryCashFlowItem(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .FactoryBudgetItem:
                return $0?.tooltipFactoryBudgetItem(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .PopAccount:
                return $0?.tooltipPopAccount(
                    try arguments[0].decode(),
                )
            case .PopActive:
                return $0?.tooltipPopActive(
                    try arguments[0].decode(),
                )
            case .PopActiveHelp:
                return $0?.tooltipPopActiveHelp(
                    try arguments[0].decode(),
                )
            case .PopVacant:
                return $0?.tooltipPopVacant(
                    try arguments[0].decode(),
                )
            case .PopVacantHelp:
                return $0?.tooltipPopVacantHelp(
                    try arguments[0].decode(),
                )
            case .PopJobs:
                return $0?.tooltipPopJobs(
                    try arguments[0].decode(),
                )
            case .PopResourceIO:
                return $0?.tooltipPopResourceIO(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .PopResourceOrigin:
                return $0?.tooltipPopResourceOrigin(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .PopStockpile:
                return $0?.tooltipPopStockpile(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .PopExplainPrice:
                return $0?.tooltipPopExplainPrice(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .PopNeeds:
                return $0?.tooltipPopNeeds(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .PopType:
                return $0?.tooltipPopType(
                    try arguments[0].decode(),
                )
            case .PopOwnershipCountry:
                return $0?.tooltipPopOwnership(
                    try arguments[0].decode(),
                    country: try arguments[1].decode(),
                )
            case .PopOwnershipCulture:
                return $0?.tooltipPopOwnership(
                    try arguments[0].decode(),
                    culture: try arguments[1].decode(),
                )
            case .PopOwnershipSecurities:
                return $0?.tooltipPopOwnership(
                    try arguments[0].decode(),
                )
            case .PopCashFlowItem:
                return $0?.tooltipPopCashFlowItem(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .PopBudgetItem:
                return $0?.tooltipPopBudgetItem(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .MarketLiquidity:
                return $0?.tooltipMarketLiquidity(
                    try arguments[0].decode(),
                )
            case .PlanetCell:
                return $0?.tooltipPlanetCell(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                    try arguments[2].decode(),
                )
            case .TileCulture:
                return $0?.tooltipTileCulture(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .TilePopType:
                return $0?.tooltipTilePopType(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            }
        }
    }
}

#if TESTABLE
extension GameSession {
    public func run(until date: GameDate) throws {
        try self.state.run(until: date)
    }

    public var _hash: Int {
        self.state._hash
    }

    public var rules: GameMetadata { self.state.context.rules }
}
#endif
