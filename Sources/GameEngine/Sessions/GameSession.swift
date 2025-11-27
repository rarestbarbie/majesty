import GameIDs
import GameRules
import GameTerrain
import GameUI
import HexGrids
import JavaScriptInterop
import JavaScriptKit

public struct GameSession: ~Copyable {
    private var context: GameContext
    private var world: GameWorld
    private var ui: GameUI

    private init(context: GameContext, world: consuming GameWorld) {
        self.context = context
        self.world = world
        self.ui = .init()
    }
}
extension GameSession {
    public static func load(
        _ save: consuming GameSave,
        rules: borrowing GameRulesDescription,
        map: borrowing TerrainMap,
    ) throws -> Self {
        let rules: GameRules = try .init(resolving: rules, with: &save.symbols)
        return try .load(save, rules: rules, map: map)
    }
    public static func load(
        start: consuming GameStart,
        rules: borrowing GameRulesDescription,
        map: borrowing TerrainMap,
    ) throws -> Self {
        let rules: GameRules = try .init(resolving: rules, with: &start.symbols)
        let save: GameSave = try start.unpack()
        return try .load(save, rules: rules, map: map)
    }

    private static func load(
        _ save: borrowing GameSave,
        rules: consuming GameRules,
        map: borrowing TerrainMap,
    ) throws -> Self {
        let world: GameWorld = .init(
            notifications: .init(date: save.date),
            bank: .init(accounts: save.accounts.dictionary),
            segmentedMarkets: save.segmentedMarkets,
            tradeableMarkets: save.tradeableMarkets,
            random: save.random,
        )

        var context: GameContext = try .load(save, rules: rules)
        try context.loadTerrain(map)

        return .init(context: context, world: world)
    }

    public var save: GameSave {
        self.context.save(self.world)
    }
}
extension GameSession {
    public mutating func loadTerrain(from editor: PlanetTileEditor) throws {
        try self.context.loadTerrain(from: editor)
    }

    public func editTerrain() -> PlanetTileEditor? {
        guard
        case (_, let current?) = self.ui.navigator.current,
        let planet: PlanetContext = self.context.planets[current.planet],
        let tile: PlanetGrid.Tile = planet.grid.tiles[current.tile] else {
            return nil
        }

        return .init(
            id: tile.id,
            rotate: nil,
            size: planet.grid.size,
            name: tile.name,
            terrain: tile.terrain.symbol,
            terrainChoices: self.context.rules.terrains.values.map(\.symbol),
            geology: tile.geology.symbol,
            geologyChoices: self.context.rules.geology.values.map(\.symbol)
        )
    }

    public func saveTerrain() -> TerrainMap { self.context.saveTerrain() }
}
extension GameSession {
    private var snapshot: GameSnapshot {
        .init(
            context: self.context,
            markets: (self.world.tradeableMarkets, self.world.segmentedMarkets),
            bank: self.world.bank,
            date: self.world.date
        )
    }

    public var rules: GameRules {
        self.context.rules
    }

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
        try self.context.compute(&self.world)
        try self.ui.sync(with: self.snapshot)
        return self.ui
    }

    public mutating func tick() throws -> GameUI {
        if  self.ui.clock.tick() {
            try self.context.advance(&self.world[self.rules.settings])
            try self.context.compute(&self.world)
        }

        try self.ui.sync(with: self.snapshot)
        return self.ui
    }

    public mutating func open(_ screen: GameUI.ScreenType?) {
        self.ui.screen = screen
    }

    public mutating func openPlanet(_ request: PlanetReportRequest) throws -> PlanetReport {
        self.ui.screen = .Planet
        return try self.ui.report.planet.open(request: request, snapshot: self.snapshot)
    }

    public mutating func openInfrastructure(
        _ request: InfrastructureReportRequest
    ) throws -> InfrastructureReport {
        self.ui.screen = .Infrastructure
        return try self.ui.report.infrastructure.open(request: request, snapshot: self.snapshot)
    }

    public mutating func openProduction(
        _ request: ProductionReportRequest
    ) throws -> ProductionReport {
        self.ui.screen = .Production
        return try self.ui.report.production.open(request: request, snapshot: self.snapshot)
    }

    public mutating func openPopulation(
        _ request: PopulationReportRequest
    ) throws -> PopulationReport {
        self.ui.screen = .Population
        return try self.ui.report.population.open(request: request, snapshot: self.snapshot)
    }

    public mutating func openTrade(_ request: TradeReportRequest) throws -> TradeReport {
        self.ui.screen = .Trade
        return try self.ui.report.trade.open(request: request, snapshot: self.snapshot)
    }

    public mutating func minimap(
        planet: PlanetID,
        layer: MinimapLayer?,
        cell: HexCoordinate?
    ) -> Navigator {
        self.ui.navigator.select(planet: planet, layer: layer, cell: cell)
        self.ui.navigator.update(in: self.context)
        return self.ui.navigator
    }

    public mutating func view(_ index: Int, to system: PlanetID) throws -> CelestialView {
        let view: CelestialView = try .open(subject: system, in: self.context)
        switch index as Int {
        case 0: self.ui.views.0 = view
        case 1: self.ui.views.1 = view
        default: break
        }
        return view
    }

    public func orbit(_ id: PlanetID) -> JSTypedArray<Float>? {
        self.context.planets[id]?.motion.global?.rendered()
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
        self.context.player = id
    }
}
extension GameSession {
    private func contextMenuMinimapTile(
        _ id: PlanetID,
        _ cell: HexCoordinate,
        _ layer: MinimapLayer,
    ) -> ContextMenu? {
        guard
        let planet: PlanetContext = self.context.planets[id],
        let tile: PlanetGrid.Tile = planet.grid.tiles[cell] else {
            return nil
        }

        return .items {
            $0["Switch to Player"] {
                if  let country: CountryProperties = tile.properties?.governedBy {
                    $0[.SwitchToPlayer] = country.id
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
            return self.snapshot.tooltipBuildingAccount(
                try arguments[0].decode(),
            )
        case .BuildingActive:
            return self.snapshot.tooltipBuildingActive(
                try arguments[0].decode(),
            )
        case .BuildingVacant:
            return self.snapshot.tooltipBuildingVacant(
                try arguments[0].decode(),
            )
        case .BuildingNeeds:
            return self.snapshot.tooltipBuildingNeeds(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .BuildingResourceIO:
            return self.snapshot.tooltipBuildingResourceIO(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .BuildingStockpile:
            return self.snapshot.tooltipBuildingStockpile(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .BuildingExplainPrice:
            return self.snapshot.tooltipBuildingExplainPrice(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .BuildingOwnershipCountry:
            return self.snapshot.tooltipBuildingOwnership(
                try arguments[0].decode(),
                country: try arguments[1].decode(),
            )
        case .BuildingOwnershipCulture:
            return self.snapshot.tooltipBuildingOwnership(
                try arguments[0].decode(),
                culture: try arguments[1].decode(),
            )
        case .BuildingOwnershipSecurities:
            return self.snapshot.tooltipBuildingOwnership(
                try arguments[0].decode(),
            )
        case .BuildingCashFlowItem:
            return self.snapshot.tooltipBuildingCashFlowItem(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .BuildingBudgetItem:
            return self.snapshot.tooltipBuildingBudgetItem(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .FactoryAccount:
            return self.snapshot.tooltipFactoryAccount(
                try arguments[0].decode(),
            )
        case .FactoryClerks:
            return self.snapshot.tooltipFactoryClerks(
                try arguments[0].decode(),
            )
        case .FactoryWorkers:
            return self.snapshot.tooltipFactoryWorkers(
                try arguments[0].decode(),
            )
        case .FactorySize:
            return self.snapshot.tooltipFactorySize(
                try arguments[0].decode(),
            )
        case .FactoryNeeds:
            return self.snapshot.tooltipFactoryNeeds(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .FactoryResourceIO:
            return self.snapshot.tooltipFactoryResourceIO(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .FactoryStockpile:
            return self.snapshot.tooltipFactoryStockpile(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .FactoryExplainPrice:
            return self.snapshot.tooltipFactoryExplainPrice(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .FactorySummarizeEmployees:
            return self.snapshot.tooltipFactorySummarizeEmployees(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .FactoryOwnershipCountry:
            return self.snapshot.tooltipFactoryOwnership(
                try arguments[0].decode(),
                country: try arguments[1].decode(),
            )
        case .FactoryOwnershipCulture:
            return self.snapshot.tooltipFactoryOwnership(
                try arguments[0].decode(),
                culture: try arguments[1].decode(),
            )
        case .FactoryOwnershipSecurities:
            return self.snapshot.tooltipFactoryOwnership(
                try arguments[0].decode(),
            )
        case .FactoryCashFlowItem:
            return self.snapshot.tooltipFactoryCashFlowItem(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .FactoryBudgetItem:
            return self.snapshot.tooltipFactoryBudgetItem(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .PlanetCell:
            return self.snapshot.tooltipPlanetCell(
                try arguments[0].decode(),
                try arguments[1].decode(),
                try arguments[2].decode(),
            )
        case .PopAccount:
            return self.snapshot.tooltipPopAccount(
                try arguments[0].decode(),
            )
        case .PopJobs:
            return self.snapshot.tooltipPopJobs(
                try arguments[0].decode(),
            )
        case .PopResourceIO:
            return self.snapshot.tooltipPopResourceIO(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .PopResourceOrigin:
            return self.snapshot.tooltipPopResourceOrigin(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .PopStockpile:
            return self.snapshot.tooltipPopStockpile(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .PopExplainPrice:
            return self.snapshot.tooltipPopExplainPrice(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .PopNeeds:
            return self.snapshot.tooltipPopNeeds(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .PopType:
            return self.snapshot.tooltipPopType(
                try arguments[0].decode(),
            )
        case .PopOwnershipCountry:
            return self.snapshot.tooltipPopOwnership(
                try arguments[0].decode(),
                country: try arguments[1].decode(),
            )
        case .PopOwnershipCulture:
            return self.snapshot.tooltipPopOwnership(
                try arguments[0].decode(),
                culture: try arguments[1].decode(),
            )
        case .PopOwnershipSecurities:
            return self.snapshot.tooltipPopOwnership(
                try arguments[0].decode(),
            )
        case .PopCashFlowItem:
            return self.snapshot.tooltipPopCashFlowItem(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .PopBudgetItem:
            return self.snapshot.tooltipPopBudgetItem(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .MarketLiquidity:
            return self.snapshot.tooltipMarketLiquidity(
                try arguments[0].decode(),
            )
        case .TileCulture:
            return self.snapshot.tooltipTileCulture(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        case .TilePopType:
            return self.snapshot.tooltipTilePopType(
                try arguments[0].decode(),
                try arguments[1].decode(),
            )
        }
    }
}

#if TESTABLE
extension GameSession {
    public mutating func run(until date: GameDate) throws {
        try self.context.compute(&self.world)
        while self.world.date < date {
            try self.context.advance(&self.world[self.rules.settings])
            try self.context.compute(&self.world)

            if case (year: let year, month: 1, day: 1) = self.world.date.gregorian {
                print("Year \(year) has started.")
            }
        }
    }

    public var _hash: Int {
        var hasher: Hasher = .init()
        self.context.pops.state.hash(into: &hasher)
        self.context.factories.state.hash(into: &hasher)
        return hasher.finalize()
    }

    public static func != (a: borrowing Self, b: borrowing Self) -> Bool {
        a.context.pops.state != b.context.pops.state ||
        a.context.factories.state != b.context.factories.state
    }
}
#endif
