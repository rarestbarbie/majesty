import ColorText
import D
import GameConditions
import GameEconomy
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

    public mutating func openPlanet(
        subject: PlanetID?,
        details: PlanetDetailsTab? = nil
    ) throws -> PlanetReport {
        self.ui.screen = .Planet
        return try self.ui.report.planet.open(
            subject: subject,
            details: details,
            filter: nil,
            snapshot: self.snapshot
        )
    }

    public mutating func openProduction(
        subject: FactoryID?,
        details: FactoryDetailsTab?
    ) throws -> ProductionReport {
        self.ui.screen = .Production
        return try self.ui.report.production.open(
            subject: subject,
            details: details,
            filter: nil,
            snapshot: self.snapshot
        )
    }

    public mutating func openPopulation(
        subject: PopID?,
        details: PopDetailsTab?
    ) throws -> PopulationReport {
        self.ui.screen = .Population
        return try self.ui.report.population.open(
            subject: subject,
            details: details,
            filter: nil,
            snapshot: self.snapshot
        )
    }

    public mutating func openTrade(
        subject: Market.AssetPair?,
        filter: Market.Asset?
    ) throws -> TradeReport {
        self.ui.screen = .Trade
        return try self.ui.report.trade.open(
            subject: subject,
            details: nil,
            filter: filter,
            snapshot: self.snapshot
        )
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

        let y: Factory.Dimensions = factory.yesterday
        let t: Factory.Dimensions = factory.today

        let liquid: (y: Int64, t: Int64) = (factory.cash.liq, factory.cash.balance)
        let assets: (y: Int64, t: Int64) = (y.vi + y.vv, t.vi + t.vv)
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
                $0["Stockpiled equipment", +] = t.vv[/3] <- y.vv
            }

            $0["Liquid assets", +] = liquid.t[/3] <- liquid.y
            $0[>] {
                $0["Market spending", +] = +factory.cash.b[/3]
                $0["Market spending (amortized)", +] = +?(factory.cash.b + factory.Δ.vi)[/3]
                $0["Market earnings", +] = +?factory.cash.r[/3]
                $0["Subsidies", +] = +?factory.cash.s[/3]
                $0["Salaries", +] = +?factory.cash.c[/3]
                $0["Wages", +] = +?factory.cash.w[/3]
                $0["Interest and dividends", +] = +?factory.cash.i[/3]
                if factory.cash.e < 0 {
                    $0["Stock buybacks", +] = factory.cash.e[/3]
                } else {
                    $0["Market capitalization", +] = +?factory.cash.e[/3]
                }
                $0["Capital expenditures", +] = +?factory.cash.v[/3]
            }
        }
    }

    public func tooltipFactoryDemand(
        _ id: FactoryID,
        _ tier: ResourceTierIdentifier,
        _ need: Resource,
    ) -> Tooltip? {
        guard let factory: FactoryContext = self.context.factories[id] else {
            return nil
        }

        switch tier {
        case .i:
            return factory.state.ni.tooltipDemand(
                need,
                tier: factory.type.inputs,
                unit: "worker",
                factor: 1
            )
        case .v:
            return factory.state.nv.tooltipDemand(
                need,
                tier: factory.type.costs,
                unit: "level",
                factor: 1
            )
        default:
            return nil
        }
    }

    public func tooltipFactorySupply(
        _ id: FactoryID,
        _ need: Resource,
    ) -> Tooltip? {
        guard let factory: FactoryContext = self.context.factories[id] else {
            return nil
        }

        return factory.state.out.tooltipSupply(
            need,
            tier: factory.type.output,
            unit: "worker",
            factor: factory.state.today.eo
        )
    }

    public func tooltipFactoryStockpile(
        _ id: FactoryID,
        _ tier: ResourceTierIdentifier,
        _ need: Resource,
    ) -> Tooltip? {
        guard let factory: FactoryContext = self.context.factories[id] else {
            return nil
        }

        switch tier {
        case .i:
            return factory.state.ni.tooltipStockpile(need)
        case .v:
            return factory.state.nv.tooltipStockpile(need)
        default:
            return nil
        }
    }

    public func tooltipFactoryExplainPrice(
        _ id: FactoryID,
        _ tier: ResourceTierIdentifier?,
        _ need: Resource,
    ) -> Tooltip? {
        guard
        let factory: FactoryContext = self.context.factories[id],
        let country: CountryProperties = context.planets[factory.state.tile]?.occupiedBy else {
            return nil
        }

        let market: (
            inelastic: (yesterday: LocalMarketState, today: LocalMarketState)?,
            tradeable: Candle<Double>?
        ) = (
            nil, // self.map.localMarkets[factory.state.home, need].history,
            self.map.exchange.markets[need / country.currency.id]?.history.last?.prices
        )

        switch tier {
        case .i?:
            return factory.state.ni.tooltipExplainPrice(need, market, country)
        case .v?:
            return factory.state.nv.tooltipExplainPrice(need, market, country)
        case nil:
            return factory.state.out.tooltipExplainPrice(need, market, country)
        default:
            return nil
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

        let workforce: FactoryContext.Workforce
        let type: PopType

        if case .Worker = stratum,
            let workers: FactoryContext.Workforce = factory.workers {
            workforce = workers
            type = factory.type.workers.unit
        } else if
            let clerks: FactoryContext.Workforce = factory.clerks,
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

    public func tooltipFactoryStatementItem(
        _ id: FactoryID,
        _ item: CashFlowItem,
    ) -> Tooltip? {
        self.context.factories[id]?.cashFlow.tooltip(
            rules: self.context.rules,
            item: item
        )
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
                $0["Population"] = tile.population[/3]

            case .AverageMilitancy:
                let value: Double = tile.population > 0
                    ? (tile.weighted.mil / Double.init(tile.population))
                    : 0
                $0["Average militancy"] = value[..2]
            case .AverageConsciousness:
                let value: Double = tile.population > 0
                    ? (tile.weighted.con / Double.init(tile.population))
                    : 0
                $0["Average consciousness"] = value[..2]
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

        return .instructions {
            $0["Liquid assets", +] = pop.cash.balance[/3] <- pop.cash.liq
            $0[>] {
                $0["Market earnings", +] = +?pop.cash.r[/3]
                $0["Welfare", +] = +?pop.cash.s[/3]
                $0["Salaries", +] = +?pop.cash.c[/3]
                $0["Wages", +] = +?pop.cash.w[/3]
                $0["Interest and dividends", +] = +?pop.cash.i[/3]

                $0["Market spending", +] = +?pop.cash.b[/3]
                $0["Stock sales", +] = +?pop.cash.v[/3]
                if case .Ward = pop.type.stratum {
                    $0["Loans taken", +] = +?pop.cash.e[/3]
                } else {
                    $0["Investments", +] = +?pop.cash.e[/3]
                }

                $0["Inheritances", +] = +?pop.cash.d[/3]
            }
        }
    }

    public func tooltipPopJobs(_ id: PopID) -> Tooltip? {
        guard let pop: Pop = self.context.pops.state[id] else {
            return nil
        }

        let total: (
            count: Int64,
            hired: Int64,
            fired: Int64,
            quit: Int64
        ) = pop.jobs.values.reduce(into: (0, 0, 0, 0)) {
            $0.count += $1.count
            $0.hired += $1.hired
            $0.fired += $1.fired
            $0.quit += $1.quit
        }

        return .instructions {
            $0["Total employment"] = total.count[/3]
            $0[>] {
                for job: FactoryJob in pop.jobs.values {
                    let change: Int64 = job.hired - job.fired - job.quit
                    let name: String = self.context.factories[job.at]?.type.name ?? "Unknown"
                    $0[name, +] = job.count[/3] <- job.count - change
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
            default:
                return
            }
        }
    }

    public func tooltipPopDemand(
        _ id: PopID,
        _ tier: ResourceTierIdentifier,
        _ need: Resource,
    ) -> Tooltip? {
        guard let pop: PopContext = self.context.pops[id] else {
            return nil
        }

        switch tier {
        case .l:
            return pop.state.nl.tooltipDemand(
                need,
                tier: pop.type.l,
                unit: "capita",
                factor: pop.state.needsPerCapita.l
            )
        case .e:
            return pop.state.ne.tooltipDemand(
                need,
                tier: pop.type.e,
                unit: "capita",
                factor: pop.state.needsPerCapita.e
            )
        case .x:
            return pop.state.nx.tooltipDemand(
                need,
                tier: pop.type.x,
                unit: "capita",
                factor: pop.state.needsPerCapita.x
            )
        default:
            return nil
        }
    }

    public func tooltipPopSupply(
        _ id: PopID,
        _ need: Resource,
    ) -> Tooltip? {
        guard let pop: PopContext = self.context.pops[id] else {
            return nil
        }

        return pop.state.out.tooltipSupply(
            need,
            tier: pop.type.output,
            unit: "worker",
            factor: 1
        )
    }

    public func tooltipPopStockpile(
        _ id: PopID,
        _ tier: ResourceTierIdentifier,
        _ need: Resource,
    ) -> Tooltip? {
        guard let pop: PopContext = self.context.pops[id] else {
            return nil
        }

        switch tier {
        case .l:
            return pop.state.nl.tooltipStockpile(need)
        case .e:
            return pop.state.ne.tooltipStockpile(need)
        case .x:
            return pop.state.nx.tooltipStockpile(need)
        default:
            return nil
        }
    }

    public func tooltipPopExplainPrice(
        _ pop: PopID,
        _ tier: ResourceTierIdentifier?,
        _ need: Resource,
    ) -> Tooltip? {
        guard
        let pop: PopContext = self.context.pops[pop],
        let country: CountryProperties = context.planets[pop.state.home]?.occupiedBy else {
            return nil
        }

        let market: (
            inelastic: (yesterday: LocalMarketState, today: LocalMarketState)?,
            tradeable: Candle<Double>?
        ) = (
            self.map.localMarkets[pop.state.home, need].history,
            self.map.exchange.markets[need / country.currency.id]?.history.last?.prices
        )

        switch tier {
        case .l?:
            return pop.state.nl.tooltipExplainPrice(need, market, country)
        case .e?:
            return pop.state.ne.tooltipExplainPrice(need, market, country)
        case .x?:
            return pop.state.nx.tooltipExplainPrice(need, market, country)
        case nil:
            return pop.state.out.tooltipExplainPrice(need, market, country)
        default:
            return nil
        }
    }

    public func tooltipPopType(
        _ id: PopID,
    ) -> Tooltip? {
        guard
        let pop: PopContext = self.context.pops[id],
        let country: CountryProperties = self.context.planets[pop.state.home]?.occupiedBy else {
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

    public func tooltipPopStatementItem(
        _ id: PopID,
        _ item: CashFlowItem,
    ) -> Tooltip? {
        self.context.pops[id]?.cashFlow.tooltip(rules: self.context.rules, item: item)
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

        let (share, total): (share: Int64, total: Int64) = tile.pops.reduce(
            into: (0, 0)
        ) {
            guard let pop: Pop = context.pops.state[$1] else {
                return
            }

            if  culture == pop.nat {
                $0.share += pop.today.size
            }
            $0.total += pop.today.size
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

        let (share, total): (share: Int64, total: Int64) = tile.pops.reduce(
            into: (0, 0)
        ) {
            guard let pop: Pop = context.pops.state[$1] else {
                return
            }

            if  type == pop.type {
                $0.share += pop.today.size
            }
            $0.total += pop.today.size
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
