import ColorText
import D
import GameConditions
import GameEconomy
import GameRules
import GameState
import GameTerrain
import HexGrids
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
        self.map = .init(settings: rules.settings, markets: save.markets)
        self.ui = .init()
    }
}
extension GameSession {
    public mutating func loadTerrain(from editor: PlanetTileEditor) throws {
        self.context.loadTerrain(from: editor)
    }

    public func editTerrain() -> PlanetTileEditor? {
        guard
        case (_, let current?) = self.ui.navigator.current,
        let planet: PlanetContext = self.context.planets[current.planet],
        let cell: PlanetContext.Cell = planet.cells[current.tile] else {
            return nil
        }

        return .init(
            id: cell.id,
            on: planet.state.id,
            rotate: nil,
            size: planet.size,
            tile: cell.tile,
            type: cell.type.id,
            terrainLabels: self.context.rules.terrains.values.map(\.name),
            terrainChoices: self.context.rules.terrains.keys.map(\.self),
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
    public mutating func `switch`(to planet: PlanetID) throws -> GameUI {
        if  let country: CountryID = self.context.planets[planet]?.occupied {
            self.context.player = country
            try self.ui.sync(with: self.snapshot)
        }
        return self.ui
    }

    private mutating func `switch`(to player: CountryID) throws -> GameUI {
        self.context.player = player
        try self.ui.sync(with: self.snapshot)
        return self.ui
    }
}
extension GameSession {
    private var snapshot: GameSnapshot {
        .init(
            context: self.context,
            markets: (self.map.exchange.markets, self.map.localMarkets)
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
        try self.context.compute()
        try self.ui.sync(with: self.snapshot)
        return self.ui
    }

    public mutating func tick() throws -> GameUI {
        if  self.ui.clock.tick() {
            try self.context.advance(&self.map)
            try self.context.compute()
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

    public mutating func openPopulation(subject: PopID?) throws -> PopulationReport {
        self.ui.screen = .Population
        return try self.ui.report.population.open(
            subject: subject,
            details: nil,
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
    public func tooltipFactoryAccount(_ id: FactoryID) -> Tooltip? {
        guard let factory: Factory = self.context.factories.state[id] else {
            return nil
        }

        let y: Factory.Dimensions = factory.yesterday
        let t: Factory.Dimensions = factory.today

        let liquid: (y: Int64, t: Int64) = (factory.cash.liq, factory.cash.balance)
        let assets: (y: Int64, t: Int64) = (y.vi + y.vv, t.vi + t.vv)
        let value: (y: Int64, t: Int64) = (liquid.y + assets.y, liquid.t + assets.t)

        /// Does not include subsidies, or changes in stockpiled equipment!
        let consumed: Int64 = t.vi - y.vi
        let profit: Int64 = consumed
            + factory.cash.v
            + factory.cash.b
            + factory.cash.r
            + factory.cash.c
            + factory.cash.w

        return .instructions {
            $0["Total valuation", +] = value.t[/3] <- value.y
            $0[>] {
                $0["Today’s profit", +] = +profit[/3]
            }

            $0["Illiquid assets", +] = assets.t[/3] <- assets.y
            $0[>] {
                $0["Stockpiled inputs", +] = t.vi[/3] <- y.vi
                $0["Stockpiled equipment", +] = t.vv[/3] <- y.vv
            }

            $0["Liquid assets", +] = liquid.t[/3] <- liquid.y
            $0[>] {
                $0["Capital expenditures", +] = +?factory.cash.v[/3]
                $0["Market spending", +] = +?factory.cash.b[/3]
                $0["Market earnings", +] = +?factory.cash.r[/3]
                $0["Subsidies", +] = +?factory.cash.s[/3]
                $0["Salaries", +] = +?factory.cash.c[/3]
                $0["Wages", +] = +?factory.cash.w[/3]
                $0["Interest and dividends", +] = +?factory.cash.i[/3]
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
        let country: CountryID = context.planets[factory.state.on.planet]?.occupied,
        let country: Country = self.context.countries.state[country] else {
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
        guard let factory: Factory = self.context.factories.state[id] else {
            return nil
        }
        return .instructions {
            $0["Effective size"] = factory.size.value[/3]
            $0["Growth progress"] = factory.size.growthProgress[/0] / Factory.Size.growthRequired

            $0[>] = """
            Doubling the factory level will quadruple its capacity
            """
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

        if case .Worker = stratum {
            workforce = factory.workers
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
        guard
        let factory: FactoryContext = self.context.factories[id],
        let culture: Culture = self.context.cultures.state[culture] else {
            return nil
        }

        let (share, total): (share: Int64, total: Int64) = factory.equity.owners.reduce(
            into: (0, 0)
        ) {
            guard let pop: Pop = self.context.pops.table.state[$1.id] else {
                return
            }
            if  pop.nat == culture.id {
                $0.share += $1.count
            }
            $0.total += $1.count
        }

        return .instructions(style: .borderless) {
            $0[culture.id] = (Double.init(share) / Double.init(total))[%3]
        }
    }

    public func tooltipFactoryOwnership(
        _ id: FactoryID,
        country: CountryID,
    ) -> Tooltip? {
        guard
        let factory: FactoryContext = self.context.factories[id],
        let country: Country = self.context.countries.state[country] else {
            return nil
        }

        let (share, total): (share: Int64, total: Int64) = factory.equity.owners.reduce(
            into: (0, 0)
        ) {
            guard let pop: Pop = self.context.pops.table.state[$1.id] else {
                return
            }
            if case country.id? = self.context.planets[pop.home.planet]?.occupied {
                $0.share += $1.count
            }
            $0.total += $1.count
        }

        return .instructions(style: .borderless) {
            $0[country.name] = (Double.init(share) / Double.init(total))[%3]
        }
    }

    public func tooltipFactoryStatementItem(
        _ id: FactoryID,
        _ item: CashFlowItem,
    ) -> Tooltip? {
        self.context.factories[id]?.cashFlow.tooltip(rules: self.context.rules, item: item)
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
        let cell: PlanetContext.Cell = planet.cells[cell] else {
            return nil
        }

        return .instructions(style: .borderless) {
            switch layer {
            case .Terrain:
                if let geology: String = cell.tile.geology {
                    $0[>] = "\(cell.type.name) (\(geology))"
                } else {
                    $0[>] = "\(cell.type.name)"
                }

            case .Population:
                $0["Population"] = cell.population[/3]

            case .AverageMilitancy:
                let value: Double = cell.population > 0
                    ? (cell.weighted.mil / Double.init(cell.population))
                    : 0
                $0["Average militancy"] = value[..2]
            case .AverageConsciousness:
                let value: Double = cell.population > 0
                    ? (cell.weighted.con / Double.init(cell.population))
                    : 0
                $0["Average consciousness"] = value[..2]
            }

            if let name: String = cell.tile.name {
                $0[>] = "\(name)"
            }
        }
    }
}
extension GameSession {
    public func tooltipPopAccount(_ id: PopID) -> Tooltip? {
        guard let pop: Pop = self.context.pops.table.state[id] else {
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
                $0["Investments", +] = +?pop.cash.v[/3]
            }
        }
    }

    public func tooltipPopJobs(_ id: PopID) -> Tooltip? {
        guard let pop: Pop = self.context.pops.table.state[id] else {
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
        guard let pop: Pop = self.context.pops.table.state[id] else {
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
        guard let pop: PopContext = self.context.pops.table[id] else {
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
        guard let pop: PopContext = self.context.pops.table[id] else {
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
        guard let pop: PopContext = self.context.pops.table[id] else {
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
        let pop: PopContext = self.context.pops.table[pop],
        let country: CountryID = context.planets[pop.state.home.planet]?.occupied,
        let country: Country = self.context.countries.state[country] else {
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
        let pop: PopContext = self.context.pops.table[id],
        let country: CountryID = context.planets[pop.state.home.planet]?.occupied,
        let country: Country = self.context.countries.state[country]
        else {
            return nil
        }

        let promotion: ConditionBreakdown = pop.buildPromotionMatrix(country: country.policies)
        let demotion: ConditionBreakdown = pop.buildDemotionMatrix(country: country.policies)

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

    public func tooltipPopStatementItem(
        _ id: PopID,
        _ item: CashFlowItem,
    ) -> Tooltip? {
        self.context.pops.table[id]?.cashFlow.tooltip(rules: self.context.rules, item: item)
    }
}
extension GameSession {
    public func tooltipMarketLiquidity(
        _ id: Market.AssetPair
    ) -> Tooltip? {
        guard
        let market: Market = self.map.exchange.markets[id],
        let last: Int = market.history.indices.last
        else {
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
        let cell: PlanetContext.Cell = planet.cells[id.tile] else {
            return nil
        }

        let (share, total): (share: Int64, total: Int64) = cell.pops.reduce(
            into: (0, 0)
        ) {
            guard let pop: Pop = context.pops.table.state[$1] else {
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
        let cell: PlanetContext.Cell = planet.cells[id.tile] else {
            return nil
        }

        let (share, total): (share: Int64, total: Int64) = cell.pops.reduce(
            into: (0, 0)
        ) {
            guard let pop: Pop = context.pops.table.state[$1] else {
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
        try self.context.compute()
        while self.context.date < date {
            try self.context.advance(&self.map)
            try self.context.compute()

            if case (year: let year, month: 1, day: 1) = self.context.date.gregorian {
                print("Year \(year) has started.")
            }
        }
    }

    public var _hash: Int {
        var hasher: Hasher = .init()
        self.context.pops.table.state.hash(into: &hasher)
        self.context.factories.state.hash(into: &hasher)
        return hasher.finalize()
    }

    public static func != (a: borrowing Self, b: borrowing Self) -> Bool {
        a.context.pops.table.state != b.context.pops.table.state ||
        a.context.factories.state != b.context.factories.state
    }
}
#endif
