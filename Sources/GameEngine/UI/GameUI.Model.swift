import GameIDs
import GameRules
import GameUI
import HexGrids
import JavaScriptInterop
import Synchronization

extension GameUI {
    public actor Model {
        nonisolated let cachePointer: Mutex<Reference<GameUI.Cache>?>
        nonisolated let statePointer: Mutex<Reference<GameUI>?>
        var ui: GameUI

        public init(ui: consuming GameUI) {
            self.cachePointer = .init(nil)
            self.statePointer = .init(nil)
            self.ui = ui
        }
    }
}
extension GameUI.Model {
    public nonisolated var state: Reference<GameUI>? {
        self.statePointer.withLock { $0 }
    }

    private func publish() {
        let state: Reference<GameUI> = .init(value: self.ui)
        self.statePointer.withLock { $0 = state }
    }

    private nonisolated func cache<T>(
        yield: (borrowing GameUI.Cache) throws -> T?
    ) rethrows -> T? {
        if  let cache: Reference<GameUI.Cache> = (self.cachePointer.withLock { $0 }) {
            return try yield(cache.value)
        } else {
            return nil
        }
    }

    public func sync() throws {
        try self.cache {
            try self.ui.sync(with: $0)
        }

        self.publish()
    }
}
extension GameUI.Model {
    public func open(_ screen: GameUI.ScreenType?) async {
        self.ui.screen = screen
    }

    public func openPlanet(
        _ request: PlanetReportRequest
    ) async throws -> PlanetReport {
        self.ui.screen = .Planet
        self.ui.report.planet.select(request: request)
        self.cache { self.ui.report.planet.update(from: $0) }
        self.publish()
        return self.ui.report.planet
    }

    public func openInfrastructure(
        _ request: InfrastructureReportRequest
    ) async throws -> InfrastructureReport {
        self.ui.screen = .Infrastructure
        self.ui.report.infrastructure.select(request: request)
        self.cache { self.ui.report.infrastructure.update(from: $0) }
        self.publish()
        return self.ui.report.infrastructure
    }

    public func openProduction(
        _ request: ProductionReportRequest
    ) async throws -> ProductionReport {
        self.ui.screen = .Production
        self.ui.report.production.select(request: request)
        self.cache { self.ui.report.production.update(from: $0) }
        self.publish()
        return self.ui.report.production
    }

    public func openPopulation(
        _ request: PopulationReportRequest
    ) async throws -> PopulationReport {
        self.ui.screen = .Population
        self.ui.report.population.select(request: request)
        self.cache { self.ui.report.population.update(from: $0) }
        self.publish()
        return self.ui.report.population
    }

    public func openTrade(
        _ request: TradeReportRequest
    ) async throws -> TradeReport {
        self.ui.screen = .Trade
        self.ui.report.trade.select(request: request)
        self.cache { self.ui.report.trade.update(from: $0) }
        self.publish()
        return self.ui.report.trade
    }

    public func minimap(
        _ request: NavigatorRequest
    ) async -> Navigator {
        self.ui.navigator.select(request: request)
        self.cache { self.ui.navigator.update(in: $0) }
        self.publish()
        return self.ui.navigator
    }

    public func view(_ index: Int, to system: PlanetID) throws -> CelestialView? {
        let view: CelestialView? = try self.cache {
            try .open(subject: system, in: $0)
        }
        switch index as Int {
        case 0: self.ui.views.0 = view
        case 1: self.ui.views.1 = view
        default: break
        }
        self.publish()
        return view
    }
}
extension GameUI.Model {
    public nonisolated func contextMenu(
        type: ContextMenuType,
        with arguments: borrowing JavaScriptDecoder<JavaScriptArrayKey>
    ) throws -> ContextMenu? {
        try self.cache {
            switch type {
            case .MinimapTile:
                return $0.contextMenuMinimapTile(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            }
        }
    }

    public nonisolated func orbit(_ id: PlanetID) -> CelestialMotion? {
        self.cache { $0.planets[id]?.motion.global }
    }

    public nonisolated func tooltip(
        type: TooltipType,
        with arguments: borrowing JavaScriptDecoder<JavaScriptArrayKey>
    ) throws -> Tooltip? {
        try self.cache {
            switch type {
            case .BuildingAccount:
                return $0.tooltipBuildingAccount(
                    try arguments[0].decode(),
                )
            case .BuildingActive:
                return $0.tooltipBuildingActive(
                    try arguments[0].decode(),
                )
            case .BuildingActiveHelp:
                return $0.tooltipBuildingActiveHelp(
                    try arguments[0].decode(),
                )
            case .BuildingVacant:
                return $0.tooltipBuildingVacant(
                    try arguments[0].decode(),
                )
            case .BuildingVacantHelp:
                return $0.tooltipBuildingVacantHelp(
                    try arguments[0].decode(),
                )
            case .BuildingNeeds:
                return $0.tooltipBuildingNeeds(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .BuildingResourceIO:
                return $0.tooltipBuildingResourceIO(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .BuildingStockpile:
                return $0.tooltipBuildingStockpile(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .BuildingExplainPrice:
                return $0.tooltipBuildingExplainPrice(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .BuildingOwnershipCountry:
                return $0.tooltipBuildingOwnership(
                    try arguments[0].decode(),
                    country: try arguments[1].decode(),
                )
            case .BuildingOwnershipCulture:
                return $0.tooltipBuildingOwnership(
                    try arguments[0].decode(),
                    culture: try arguments[1].decode(),
                )
            case .BuildingOwnershipGender:
                return $0.tooltipBuildingOwnership(
                    try arguments[0].decode(),
                    gender: try arguments[1].decode(),
                )
            case .BuildingOwnershipSecurities:
                return $0.tooltipBuildingOwnership(
                    try arguments[0].decode(),
                )
            case .BuildingCashFlowItem:
                return $0.tooltipBuildingCashFlowItem(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .BuildingBudgetItem:
                return $0.tooltipBuildingBudgetItem(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .FactoryAccount:
                return $0.tooltipFactoryAccount(
                    try arguments[0].decode(),
                )
            case .FactoryClerks:
                return $0.tooltipFactoryClerks(
                    try arguments[0].decode(),
                )
            case .FactoryClerksHelp:
                return $0.tooltipFactoryClerksHelp(
                    try arguments[0].decode(),
                )
            case .FactoryWorkers:
                return $0.tooltipFactoryWorkers(
                    try arguments[0].decode(),
                )
            case .FactoryWorkersHelp:
                return $0.tooltipFactoryWorkersHelp(
                    try arguments[0].decode(),
                )
            case .FactorySize:
                return $0.tooltipFactorySize(
                    try arguments[0].decode(),
                )
            case .FactoryNeeds:
                return $0.tooltipFactoryNeeds(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .FactoryResourceIO:
                return $0.tooltipFactoryResourceIO(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .FactoryStockpile:
                return $0.tooltipFactoryStockpile(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .FactoryExplainPrice:
                return $0.tooltipFactoryExplainPrice(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .FactorySummarizeEmployees:
                return $0.tooltipFactorySummarizeEmployees(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .FactoryOwnershipCountry:
                return $0.tooltipFactoryOwnership(
                    try arguments[0].decode(),
                    country: try arguments[1].decode(),
                )
            case .FactoryOwnershipCulture:
                return $0.tooltipFactoryOwnership(
                    try arguments[0].decode(),
                    culture: try arguments[1].decode(),
                )
            case .FactoryOwnershipGender:
                return $0.tooltipFactoryOwnership(
                    try arguments[0].decode(),
                    gender: try arguments[1].decode(),
                )
            case .FactoryOwnershipSecurities:
                return $0.tooltipFactoryOwnership(
                    try arguments[0].decode(),
                )
            case .FactoryCashFlowItem:
                return $0.tooltipFactoryCashFlowItem(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .FactoryBudgetItem:
                return $0.tooltipFactoryBudgetItem(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .PopAccount:
                return $0.tooltipPopAccount(
                    try arguments[0].decode(),
                )
            case .PopActive:
                return $0.tooltipPopActive(
                    try arguments[0].decode(),
                )
            case .PopActiveHelp:
                return $0.tooltipPopActiveHelp(
                    try arguments[0].decode(),
                )
            case .PopVacant:
                return $0.tooltipPopVacant(
                    try arguments[0].decode(),
                )
            case .PopVacantHelp:
                return $0.tooltipPopVacantHelp(
                    try arguments[0].decode(),
                )
            case .PopJobs:
                return $0.tooltipPopJobs(
                    try arguments[0].decode(),
                )
            case .PopResourceIO:
                return $0.tooltipPopResourceIO(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .PopResourceOrigin:
                return $0.tooltipPopResourceOrigin(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .PopStockpile:
                return $0.tooltipPopStockpile(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .PopExplainPrice:
                return $0.tooltipPopExplainPrice(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .PopNeeds:
                return $0.tooltipPopNeeds(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .PopType:
                return $0.tooltipPopType(
                    try arguments[0].decode(),
                )
            case .PopOwnershipCountry:
                return $0.tooltipPopOwnership(
                    try arguments[0].decode(),
                    country: try arguments[1].decode(),
                )
            case .PopOwnershipCulture:
                return $0.tooltipPopOwnership(
                    try arguments[0].decode(),
                    culture: try arguments[1].decode(),
                )
            case .PopOwnershipGender:
                return $0.tooltipPopOwnership(
                    try arguments[0].decode(),
                    gender: try arguments[1].decode(),
                )
            case .PopOwnershipSecurities:
                return $0.tooltipPopOwnership(
                    try arguments[0].decode(),
                )
            case .PopCashFlowItem:
                return $0.tooltipPopCashFlowItem(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .PopBudgetItem:
                return $0.tooltipPopBudgetItem(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .MarketLiquidity:
                return $0.tooltipMarketLiquidity(
                    try arguments[0].decode(),
                )
            case .MarketHistory:
                return $0.tooltipMarketHistory(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .PlanetCell:
                return $0.tooltipPlanetTile(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .TileCulture:
                return $0.tooltipTileCulture(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .TilePopType:
                return $0.tooltipTilePopType(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .TileGDP:
                // TODO: Implement Tile GDP tooltip
                return nil
            case .TileIndustry:
                return $0.tooltipTileIndustry(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .TileResourceProduced:
                return $0.tooltipTileResourceProduced(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            case .TileResourceConsumed:
                return $0.tooltipTileResourceConsumed(
                    try arguments[0].decode(),
                    try arguments[1].decode(),
                )
            }
        }
    }
}
