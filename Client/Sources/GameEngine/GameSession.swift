import ColorText
import D
import Fraction
import GameConditions
import GameEconomy
import GameIDs
import GameRules
import GameState
import GameTerrain
import HexGrids
import JavaScriptInterop
import JavaScriptKit

public struct GameSession: ~Copyable {
    private var context: GameContext
    private var map: GameMap
    private var ui: GameUI

    public init(
        save: consuming GameSave,
        rules: borrowing GameRulesDescription,
        terrain: borrowing TerrainMap,
    ) throws {
        Self.address(&save.countries)
        Self.address(&save.pops)

        let rules: GameRules = try .init(resolving: rules, with: &save.symbols)

        var context: GameContext = try .init(save: save, rules: rules)
        try context.loadTerrain(terrain)

        self.context = context
        self.map = .init(date: save.date, settings: rules.settings, markets: save.markets)
        self.ui = .init()
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
            on: planet.state.id,
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
    private static func address<ID>(
        _ objects: inout [some IdentityReplaceable<ID>]
    ) where ID: GameID {
        var highest: ID = objects.reduce(0) { max($0, $1.id) }
        for i: Int in objects.indices {
            {
                if  $0 == 0 {
                    $0 = highest.increment()
                }
            } (&objects[i].id)
        }
    }
}
extension GameSession {
    private var snapshot: GameSnapshot {
        .init(
            context: self.context,
            markets: (self.map.exchange.markets, self.map.localMarkets),
            date: self.map.date
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
        try self.context.compute(self.map)
        try self.ui.sync(with: self.snapshot)
        return self.ui
    }

    public mutating func tick() throws -> GameUI {
        if  self.ui.clock.tick() {
            try self.context.advance(&self.map)
            try self.context.compute(self.map)
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

    public mutating func openProduction(_ request: ProductionReportRequest) throws -> ProductionReport {
        self.ui.screen = .Production
        return try self.ui.report.production.open(request: request, snapshot: self.snapshot)
    }

    public mutating func openPopulation(_ request: PopulationReportRequest) throws -> PopulationReport {
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
    public func contextMenuMinimapTile(
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
                if  let country: CountryProperties = tile.governedBy {
                    $0[.SwitchToPlayer] = country.id
                }
            }
        }
    }
}
extension GameSession {
    public func tooltipFactoryAccount(_ id: FactoryID) -> Tooltip? {
        guard let factory: Factory = self.context.factories.state[id] else {
            return nil
        }

        let account: Bank.Account = factory.inventory.account
        let y: Factory.Dimensions = factory.yesterday
        let t: Factory.Dimensions = factory.today

        let liquid: (y: Int64, t: Int64) = (account.liq, account.balance)
        let assets: (y: Int64, t: Int64) = (y.vi + y.vx, t.vi + t.vx)
        let value: (y: Int64, t: Int64) = (liquid.y + assets.y, liquid.t + assets.t)

        let operatingProfit: Int64 = factory.operatingProfit
        let operatingMargin: Fraction? = factory.operatingMargin
        let grossMargin: Fraction? = factory.grossMargin

        return .instructions {
            $0["Total valuation", +] = value.t[/3] <- value.y
            $0[>] {
                $0["Today’s profit", +] = +operatingProfit[/3]
                $0["Gross margin", +] = grossMargin.map {
                    (Double.init($0))[%2]
                }
                $0["Operating margin", +] = operatingMargin.map {
                    (Double.init($0))[%2]
                }
            }

            $0["Illiquid assets", +] = assets.t[/3] <- assets.y
            $0[>] {
                $0["Stockpiled inputs", +] = t.vi[/3] <- y.vi
                $0["Stockpiled equipment", +] = t.vx[/3] <- y.vx
            }

            $0["Liquid assets", +] = liquid.t[/3] <- liquid.y
            $0[>] {
                $0["Market spending", +] = +account.b[/3]
                $0["Market spending (amortized)", +] = +?(account.b + factory.Δ.vi)[/3]
                $0["Market earnings", +] = +?account.r[/3]
                $0["Subsidies", +] = +?account.s[/3]
                $0["Salaries", +] = +?account.c[/3]
                $0["Wages", +] = +?account.w[/3]
                $0["Interest and dividends", +] = +?account.i[/3]
                if account.e < 0 {
                    $0["Stock buybacks", +] = account.e[/3]
                } else {
                    $0["Market capitalization", +] = +?account.e[/3]
                }
                $0["Capital expenditures", +] = +?account.v[/3]
            }
        }
    }

    public func tooltipFactoryResourceIO(
        _ id: FactoryID,
        _ line: InventoryLine,
    ) -> Tooltip? {
        guard let factory: FactoryContext = self.context.factories[id] else {
            return nil
        }

        switch line {
        case .l(let resource):
            return factory.state.inventory.l.tooltipDemand(
                resource,
                tier: factory.type.inputs,
                unit: "worker",
                factor: 1,
                productivity: Double.init(factory.productivity)
            )
        case .e(let resource):
            return factory.state.inventory.e.tooltipDemand(
                resource,
                tier: factory.type.office,
                unit: "worker",
                factor: 1,
                productivity: Double.init(factory.productivity)
            )
        case .x(let resource):
            return factory.state.inventory.x.tooltipDemand(
                resource,
                tier: factory.type.costs,
                unit: "level",
                factor: 1,
                productivity: Double.init(factory.productivity)
            )

        case .o(let resource):
            return factory.state.inventory.out.tooltipSupply(
                resource,
                tier: factory.type.output,
                unit: "worker",
                factor: factory.state.today.eo,
                productivity: factory.productivity
            )
        }
    }

    public func tooltipFactoryStockpile(
        _ id: FactoryID,
        _ resource: InventoryLine,
    ) -> Tooltip? {
        guard
        let factory: FactoryContext = self.context.factories[id],
        let country: CountryProperties = factory.occupiedBy else {
            return nil
        }

        switch resource {
        case .l(let id): return factory.state.inventory.l.tooltipStockpile(id, country: country)
        case .e(let id): return factory.state.inventory.e.tooltipStockpile(id, country: country)
        case .x(let id): return factory.state.inventory.x.tooltipStockpile(id, country: country)
        case .o: return nil
        }
    }

    public func tooltipFactoryExplainPrice(
        _ id: FactoryID,
        _ line: InventoryLine,
    ) -> Tooltip? {
        guard
        let factory: FactoryContext = self.context.factories[id],
        let country: CountryProperties = factory.occupiedBy else {
            return nil
        }

        let market: (
            inelastic: LocalMarket,
            tradeable: Candle<Double>?
        ) = (
            self.map.localMarkets[factory.state.tile, line.resource],
            self.map.exchange.markets[line.resource / country.currency.id]?.history.last?.prices
        )

        switch line {
        case .l(let id): return factory.state.inventory.l.tooltipExplainPrice(id, market)
        case .e(let id): return factory.state.inventory.e.tooltipExplainPrice(id, market)
        case .x(let id): return factory.state.inventory.x.tooltipExplainPrice(id, market)
        case .o(let id): return factory.state.inventory.out.tooltipExplainPrice(id, market)
        }
    }

    public func tooltipFactorySize(_ id: FactoryID) -> Tooltip? {
        guard let factory: FactoryContext = self.context.factories[id] else {
            return nil
        }
        return .instructions {
            $0["Effective size"] = factory.state.size.area?[/3]
            $0["Growth progress"] = factory.state.size.growthProgress[/0]
                / Factory.Size.growthRequired

            if  let liquidation: FactoryLiquidation = factory.state.liquidation {
                let shareCount: Int64 = factory.equity.shareCount
                $0[>] = """
                This factory has been in bankruptcy proceedings since \
                \(em: liquidation.started[.phrasal_US]) and there \(
                    shareCount == 1 ? "is" : "are"
                ) \(neg: shareCount) \(
                    shareCount == 1 ? "share" : "shares"
                ) left to liquidate
                """
            } else {
                $0[>] = """
                Doubling the factory level will quadruple its capacity
                """
            }
        }
    }

    public func tooltipFactoryWorkers(
        _ id: FactoryID,
        _ stratum: PopStratum,
    ) -> Tooltip? {
        guard let factory: FactoryContext = self.context.factories[id] else {
            return nil
        }

        let workforce: Workforce
        let type: PopType

        if case .Worker = stratum,
            let workers: Workforce = factory.workers {
            workforce = workers
            type = factory.type.workers.unit
        } else if
            let clerks: Workforce = factory.clerks,
            let clerkTeam: Quantity<PopType> = factory.type.clerks {
            workforce = clerks
            type = clerkTeam.unit
        } else {
            return nil
        }

        return .instructions {
            $0[type.plural] = workforce.count[/3] / workforce.limit

            $0["Today’s change", +] = +?(
                workforce.hired - workforce.fired - workforce.quit
            )[/3]

            $0[>] {
                $0["Hired", +] = +?workforce.hired[/3]
                $0["Fired", +] = ??(-workforce.fired)[/3]
                $0["Quit", +] = ??(-workforce.quit)[/3]
            }
        }
    }

    public func tooltipFactoryOwnership(
        _ id: FactoryID,
        culture: String,
    ) -> Tooltip? {
        self.context.factories[id]?.tooltipOwnership(
            culture: culture,
            context: self.context
        )
    }

    public func tooltipFactoryOwnership(
        _ id: FactoryID,
        country: CountryID,
    ) -> Tooltip? {
        self.context.factories[id]?.tooltipOwnership(
            country: country,
            context: self.context
        )
    }

    public func tooltipFactoryOwnership(
        _ id: FactoryID,
    ) -> Tooltip? {
        self.context.factories[id]?.tooltipOwnership()
    }

    public func tooltipFactoryCashFlowItem(
        _ id: FactoryID,
        _ item: CashFlowItem,
    ) -> Tooltip? {
        self.context.factories[id]?.cashFlow.tooltip(
            rules: self.context.rules,
            item: item
        )
    }

    public func tooltipFactoryBudgetItem(
        _ id: FactoryID,
        _ item: CashAllocationItem,
    ) -> Tooltip? {
        switch self.context.factories[id]?.budget {
        case .active(let budget)?:
            let statement: CashAllocationStatement = .init(from: budget)
            return statement.tooltip(item: item)

        default:
            return nil
        }
    }
}
extension GameSession {
    public func tooltipPlanetCell(
        _ id: PlanetID,
        _ cell: HexCoordinate,
        _ layer: MinimapLayer,
    ) -> Tooltip? {
        guard
        let planet: PlanetContext = self.context.planets[id],
        let tile: PlanetGrid.Tile = planet.grid.tiles[cell] else {
            return nil
        }

        return .instructions(style: .borderless) {
            switch layer {
            case .Terrain:
                $0[>] = "\(tile.terrain.name) (\(tile.geology.name))"

            case .Population:
                $0["Population"] = tile.pops.free.total[/3]
                $0[>] {
                    $0["Free"] = tile.pops.free.total[/3]
                    $0["Enslaved"] = ??tile.pops.enslaved.total[/3]
                }

            case .AverageMilitancy:
                let (free, _): (Double, of: Double) = tile.pops.free.mil
                $0["Average militancy"] = free[..2]
                let enslaved: (average: Double, of: Double) = tile.pops.enslaved.mil
                if  enslaved.of > 0 {
                    $0[>] = """
                    The average militancy of the slave population is \(
                        enslaved.average[..2],
                        style: enslaved.average > 1.0 ? .neg : .em
                    )
                    """
                }
            case .AverageConsciousness:
                let (free, _): (Double, of: Double) = tile.pops.free.con
                $0["Average consciousness"] = free[..2]
                let enslaved: (average: Double, of: Double) = tile.pops.enslaved.con
                if  enslaved.of > 0 {
                    $0[>] = """
                    The average consciousness of the slave population is \(
                        enslaved.average[..2],
                        style: enslaved.average > 1.0 ? .neg : .em
                    )
                    """
                }
            }

            if let name: String = tile.name {
                $0[>] = "\(name)"
            }
        }
    }
}
extension GameSession {
    public func tooltipPopAccount(_ id: PopID) -> Tooltip? {
        guard let pop: Pop = self.context.pops.state[id] else {
            return nil
        }

        let account: Bank.Account = pop.inventory.account
        let liquid: (y: Int64, t: Int64) = (account.liq, account.balance)
        let assets: (y: Int64, t: Int64) = (pop.yesterday.vi, pop.today.vi)
        let value: (y: Int64, t: Int64) = (liquid.y + assets.y, liquid.t + assets.t)

        return .instructions {
            if case .Ward = pop.type.stratum {
                let operatingProfit: Int64 = pop.operatingProfit
                let operatingMargin: Fraction? = pop.operatingMargin
                let grossMargin: Fraction? = pop.grossMargin
                $0["Total valuation", +] = value.t[/3] <- value.y
                $0[>] {
                    $0["Today’s profit", +] = +operatingProfit[/3]
                    $0["Gross margin", +] = grossMargin.map {
                        (Double.init($0))[%2]
                    }
                    $0["Operating margin", +] = operatingMargin.map {
                        (Double.init($0))[%2]
                    }
                }
            }

            $0["Illiquid assets", +] = assets.t[/3] <- assets.y

            $0["Liquid assets", +] = account.balance[/3] <- account.liq
            $0[>] {
                $0["Market earnings", +] = +?account.r[/3]
                $0["Welfare", +] = +?account.s[/3]
                $0["Salaries", +] = +?account.c[/3]
                $0["Wages", +] = +?account.w[/3]
                $0["Interest and dividends", +] = +?account.i[/3]

                $0["Market spending", +] = +?account.b[/3]
                $0["Stock sales", +] = +?account.v[/3]
                if case .Ward = pop.type.stratum {
                    $0["Loans taken", +] = +?account.e[/3]
                } else {
                    $0["Investments", +] = +?account.e[/3]
                }

                $0["Inheritances", +] = +?account.d[/3]
            }
        }
    }

    public func tooltipPopJobs(_ id: PopID) -> Tooltip? {
        guard let pop: PopContext = self.context.pops[id] else {
            return nil
        }

        if !pop.state.factories.isEmpty {
            return self.tooltipPopJobs(list: pop.state.factories.values.elements) {
                self.context.factories[$0]?.type.name ?? "Unknown"
            }
        }
        if !pop.state.mines.isEmpty {
            return self.tooltipPopJobs(list: pop.state.mines.values.elements) {
                self.context.mines[$0]?.type.name ?? "Unknown"
            }
        } else {
            let employment: Int64 = .init(
                (pop.unemployment * Double.init(pop.state.today.size)).rounded()
            )
            return .instructions {
                $0["Total employment"] = employment[/3]
                for output: ResourceOutput<Never> in pop.state.inventory.out.inelastic.values {
                    let name: String? = self.context.rules.resources[output.id]?.name
                    $0[>] = """
                    Today these \(pop.state.type.plural) sold \(
                        output.unitsSold[/3],
                        style: output.unitsSold < output.units.added ? .neg : .pos
                    ) of \
                    \(em: output.units.added[/3]) \(name ?? "?") produced
                    """
                }
            }
        }
    }
    private func tooltipPopJobs<Job>(
        list: [Job],
        name: (Job.ID) -> String
    ) -> Tooltip where Job: PopJob {
        let total: (
            count: Int64,
            hired: Int64,
            fired: Int64,
            quit: Int64
        ) = list.reduce(into: (0, 0, 0, 0)) {
            $0.count += $1.count
            $0.hired += $1.hired
            $0.fired += $1.fired
            $0.quit += $1.quit
        }

        return .instructions {
            $0["Total employment"] = total.count[/3]
            $0[>] {
                for job: Job in list {
                    let change: Int64 = job.hired - job.fired - job.quit
                    $0[name(job.id), +] = job.count[/3] <- job.count - change
                }
            }
            $0["Today’s change", +] = +?(total.hired - total.fired - total.quit)[/3]
            $0[>] {
                $0["Hired today", +] = +?total.hired[/3]
                $0["Fired today", +] = ??(-total.fired)[/3]
                $0["Quit today", +] = ??(-total.quit)[/3]
            }
        }
    }

    public func tooltipPopNeeds(
        _ id: PopID,
        _ tier: ResourceTierIdentifier
    ) -> Tooltip? {
        guard let pop: Pop = self.context.pops.state[id] else {
            return nil
        }
        return .instructions {
            switch tier {
            case .l:
                $0["Life needs fulfilled"] = pop.today.fl[%3]
            case .e:
                $0["Everyday needs fulfilled"] = pop.today.fe[%3]
            case .x:
                $0["Luxury needs fulfilled"] = pop.today.fx[%3]
            }
        }
    }

    public func tooltipPopResourceIO(
        _ id: PopID,
        _ line: InventoryLine,
    ) -> Tooltip? {
        guard let pop: PopContext = self.context.pops[id] else {
            return nil
        }

        switch line {
        case .l(let resource):
            return pop.state.inventory.l.tooltipDemand(
                resource,
                tier: pop.type.l,
                unit: "capita",
                factor: 1,
                productivity: pop.state.needsPerCapita.l,
                productivityLabel: "Consciousness"
            )
        case .e(let resource):
            return pop.state.inventory.e.tooltipDemand(
                resource,
                tier: pop.type.e,
                unit: "capita",
                factor: 1,
                productivity: pop.state.needsPerCapita.e,
                productivityLabel: "Consciousness"
            )
        case .x(let resource):
            return pop.state.inventory.x.tooltipDemand(
                resource,
                tier: pop.type.x,
                unit: "capita",
                factor: 1,
                productivity: pop.state.needsPerCapita.x,
                productivityLabel: "Consciousness"
            )
        case .o(let resource):
            return pop.state.inventory.out.tooltipSupply(
                resource,
                tier: pop.type.output,
                unit: "worker",
                factor: 1,
                productivity: 1,
            )
        }
    }

    public func tooltipPopStockpile(
        _ id: PopID,
        _ line: InventoryLine,
    ) -> Tooltip? {
        guard
        let pop: PopContext = self.context.pops[id],
        let country: CountryProperties = pop.occupiedBy else {
            return nil
        }

        switch line {
        case .l(let id): return pop.state.inventory.l.tooltipStockpile(id, country: country)
        case .e(let id): return pop.state.inventory.e.tooltipStockpile(id, country: country)
        case .x(let id): return pop.state.inventory.x.tooltipStockpile(id, country: country)
        case .o: return nil
        }
    }

    public func tooltipPopExplainPrice(
        _ pop: PopID,
        _ line: InventoryLine,
    ) -> Tooltip? {
        guard
        let pop: PopContext = self.context.pops[pop],
        let country: CountryProperties = pop.occupiedBy else {
            return nil
        }

        let market: (
            inelastic: LocalMarket,
            tradeable: Candle<Double>?
        ) = (
            self.map.localMarkets[pop.state.tile, line.resource],
            self.map.exchange.markets[line.resource / country.currency.id]?.history.last?.prices
        )

        switch line {
        case .l(let id): return pop.state.inventory.l.tooltipExplainPrice(id, market)
        case .e(let id): return pop.state.inventory.e.tooltipExplainPrice(id, market)
        case .x(let id): return pop.state.inventory.x.tooltipExplainPrice(id, market)
        case .o(let id): return pop.state.inventory.out.tooltipExplainPrice(id, market)
        }
    }

    public func tooltipPopType(
        _ id: PopID,
    ) -> Tooltip? {
        guard
        let pop: PopContext = self.context.pops[id],
        let country: CountryProperties = self.context.planets[pop.state.tile]?.occupiedBy else {
            return nil
        }

        let promotion: ConditionBreakdown = pop.buildPromotionMatrix(country: country)
        let demotion: ConditionBreakdown = pop.buildDemotionMatrix(country: country)

        let promotions: Int64 = promotion.output > 0
            ? .init(Double.init(pop.state.today.size) * promotion.output * 30)
            : 0
        let demotions: Int64 = demotion.output > 0
            ? .init(Double.init(pop.state.today.size) * demotion.output * 30)
            : 0

        return .conditions(
            .list(
                "We expect \(em: promotions) promotion(s) in the next month",
                breakdown: promotion
            ),
            .list(
                "We expect \(em: demotions) demotion(s) in the next month",
                breakdown: demotion
            ),
        )
    }

    public func tooltipPopOwnership(
        _ id: PopID,
        culture: String,
    ) -> Tooltip? {
        self.context.pops[id]?.tooltipOwnership(
            culture: culture,
            context: self.context
        )
    }

    public func tooltipPopOwnership(
        _ id: PopID,
        country: CountryID,
    ) -> Tooltip? {
        self.context.pops[id]?.tooltipOwnership(
            country: country,
            context: self.context
        )
    }

    public func tooltipPopOwnership(
        _ id: PopID,
    ) -> Tooltip? {
        self.context.pops[id]?.tooltipOwnership()
    }

    public func tooltipPopCashFlowItem(
        _ id: PopID,
        _ item: CashFlowItem,
    ) -> Tooltip? {
        self.context.pops[id]?.cashFlow.tooltip(rules: self.context.rules, item: item)
    }

    public func tooltipPopBudgetItem(
        _ id: PopID,
        _ item: CashAllocationItem,
    ) -> Tooltip? {
        if  let budget: PopBudget = self.context.pops[id]?.budget {
            let statement: CashAllocationStatement = .init(from: budget)
            return statement.tooltip(item: item)
        } else {
            return nil
        }
    }
}
extension GameSession {
    public func tooltipMarketLiquidity(
        _ id: Market.AssetPair
    ) -> Tooltip? {
        guard
        let market: Market = self.map.exchange.markets[id],
        let last: Int = market.history.indices.last else {
            return nil
        }

        let interval: (Market.Interval, Market.Interval)
        interval.1 = market.history[last]
        interval.0 = last != market.history.startIndex
            ? market.history[market.history.index(before: last)]
            : interval.1

        let flow: (quote: Int64, base: Int64) = (
            interval.1.volume.quote.i - interval.1.volume.quote.o,
            interval.1.volume.base.i - interval.1.volume.base.o
        )

        let today: (quote: Int64, base: Int64)
        let yesterday: (quote: Int64, base: Int64)

        today.quote = market.pool.assets.quote
        today.base = market.pool.assets.base

        yesterday.quote = today.quote - flow.quote
        yesterday.base = today.base - flow.base

        return .instructions {
            $0["Available liquidity", +] = interval.1.liquidity[..3] <- interval.0.liquidity
            $0[>] {
                $0["Base instrument", -] = today.base[/3] <- yesterday.base
                $0["Quote instrument", +] = today.quote[/3] <- yesterday.quote
            }
        }
    }
}
extension GameSession {
    public func tooltipTileCulture(
        _ id: Address,
        _ culture: String,
    ) -> Tooltip? {
        guard
        let planet: PlanetContext = context.planets[id.planet],
        let tile: PlanetGrid.Tile = planet.grid.tiles[id.tile] else {
            return nil
        }

        let share: Int64 = tile.pops.free.cultures[culture]
            ?? tile.pops.enslaved.cultures[culture]
            ?? 0
        let total: Int64 = tile.pops.total

        if  total == 0 {
            return nil
        }

        return .instructions(style: .borderless) {
            $0[culture] = (Double.init(share) / Double.init(total))[%3]
        }
    }
    public func tooltipTilePopType(
        _ id: Address,
        _ type: PopType,
    ) -> Tooltip? {
        guard
        let planet: PlanetContext = context.planets[id.planet],
        let tile: PlanetGrid.Tile = planet.grid.tiles[id.tile] else {
            return nil
        }

        let share: Int64 = tile.pops.type[type] ?? 0
        let total: Int64 = tile.pops.free.total

        if  total == 0 {
            return nil
        }

        return .instructions(style: .borderless) {
            $0[type.plural] = (Double.init(share) / Double.init(total))[%3]
        }
    }
}

#if TESTABLE
extension GameSession {
    public mutating func run(until date: GameDate) throws {
        try self.context.compute(self.map)
        while self.map.date < date {
            try self.context.advance(&self.map)
            try self.context.compute(self.map)

            if case (year: let year, month: 1, day: 1) = self.map.date.gregorian {
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
