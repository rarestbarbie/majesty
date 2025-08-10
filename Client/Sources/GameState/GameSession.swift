import GameEconomy
import GameEngine
import GameRules
import HexGrids
import JavaScriptKit

public struct GameSession: ~Copyable {
    private var context: GameContext
    private var map: GameMap
    private var ui: GameUI

    public init(
        save: consuming GameSave,
        rules: GameRulesDescription,
        terrain: [PlanetSurface],
    ) throws {
        Self.address(&save.planets)
        Self.address(&save.countries)
        Self.address(&save.pops)

        self.map = .init(markets: save.markets)
        self.ui = .init()

        let rules: GameRules = try .init(resolving: rules, with: &save.symbols)
        var context: GameContext = try .init(save: save, rules: rules)
        try context.loadTerrain(terrain)

        self.context = context
    }
}
extension GameSession {
    public mutating func loadTerrain(from editor: PlanetTileEditor) throws {
        self.context.loadTerrain(from: editor)
    }

    public func editTerrain() -> PlanetTileEditor? {
        guard
        case (let planet, let cell?)? = self.ui.navigator.current,
        let planet: PlanetContext = self.context.planets[planet],
        let cell: PlanetContext.Cell = planet.cells[cell] else {
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

    public func saveTerrain() -> [PlanetSurface] { self.context.saveTerrain() }
}
extension GameSession {
    private static func address<T>(_ objects: inout [some IdentityReplaceable<GameID<T>>]) {
        var highest: GameID<T> = objects.reduce(0) { max($0, $1.id) }
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
    public mutating func `switch`(to planet: GameID<Planet>) throws -> GameUI {
        if  let country: GameID<Country> = self.context.planets[planet]?.occupied {
            self.context.player = country
            try self.ui.sync(with: self.map, in: self.context)
        }
        return self.ui
    }

    private mutating func `switch`(to player: GameID<Country>) throws -> GameUI {
        self.context.player = player
        try self.ui.sync(with: self.map, in: self.context)
        return self.ui
    }
}
extension GameSession {
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
        try self.ui.sync(with: self.map, in: self.context)
        return self.ui
    }

    public mutating func tick() throws -> GameUI {
        if  self.ui.clock.tick() {
            try self.context.advance(&self.map)
            try self.context.compute()
        }

        try self.ui.sync(with: self.map, in: self.context)
        return self.ui
    }

    public mutating func open(_ screen: GameUI.ScreenType?) {
        self.ui.screen = screen
    }

    public mutating func openPlanet(
        subject: GameID<Planet>?,
        details: PlanetDetailsTab? = nil
    ) throws -> PlanetReport {
        self.ui.screen = .Planet
        return try self.ui.report.planet.open(
            subject: subject,
            details: details,
            filter: nil,
            on: self.map,
            in: self.context
        )
    }

    public mutating func openProduction(
        subject: GameID<Factory>?,
        details: FactoryDetailsTab?
    ) throws -> ProductionReport {
        self.ui.screen = .Production
        return try self.ui.report.production.open(
            subject: subject,
            details: details,
            filter: nil,
            on: self.map,
            in: self.context
        )
    }

    public mutating func openPopulation(subject: GameID<Pop>?) throws -> PopulationReport {
        self.ui.screen = .Population
        return try self.ui.report.population.open(
            subject: subject,
            details: nil,
            filter: nil,
            on: self.map,
            in: self.context
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
            on: self.map,
            in: self.context
        )
    }

    public mutating func focusPlanet(_ id: GameID<Planet>, cell: HexCoordinate?) -> Navigator {
        self.ui.navigator.select(planet: id, cell: cell)
        self.ui.navigator.update(in: self.context)
        return self.ui.navigator
    }

    public mutating func view(_ index: Int, to system: GameID<Planet>) throws -> CelestialView {
        let view: CelestialView = try .open(subject: system, in: self.context)
        switch index as Int {
        case 0: self.ui.views.0 = view
        case 1: self.ui.views.1 = view
        default: break
        }
        return view
    }

    public func orbit(_ id: GameID<Planet>) -> JSTypedArray<Float>? {
        self.context.planets[id]?.motion.global?.rendered()
    }
}
extension GameSession {
    public func tooltipFactoryAccount(_ id: GameID<Factory>) -> Tooltip? {
        guard let factory: Factory = self.context.state.factories[id] else {
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
        _ id: GameID<Factory>,
        _ tier: ResourceNeedTier,
        _ need: Resource,
    ) -> Tooltip? {
        guard let factory: FactoryContext = self.context.factories[id] else {
            return nil
        }

        let input: Quantity<Resource>?
        let stock: ResourceInput?
        let scale: Double // TODO
        switch tier {
        case .i:
            input = factory.type.inputs.first { $0.unit == need }
            stock = factory.state.ni.first { $0.id == need }
            scale = 1
        case .v:
            input = factory.type.costs.first { $0.unit == need }
            stock = factory.state.nv.first { $0.id == need }
            scale = 1
        default:
            return nil
        }

        guard
        let input: Quantity<Resource>,
        let stock: ResourceInput else {
            return nil
        }

        return .instructions {
            $0["Consumed today", +] = stock.consumed[/3] / stock.demanded

            if case .i = tier {
                $0[>] {
                    $0["Demand per worker"] = (scale * Double.init(input.amount))[..3]
                }
            }
        }
    }

    public func tooltipFactoryStockpile(
        _ id: GameID<Factory>,
        _ tier: ResourceNeedTier,
        _ need: Resource,
    ) -> Tooltip? {
        guard let factory: FactoryContext = self.context.factories[id] else {
            return nil
        }

        let stock: ResourceInput?
        switch tier {
        case .i:
            stock = factory.state.ni.first { $0.id == need }
        case .v:
            stock = factory.state.nv.first { $0.id == need }
        default:
            return nil
        }

        guard
        let stock: ResourceInput else {
            return nil
        }

        return Self.tooltipResourceStockpile(stock)
    }

    public func tooltipFactorySize(_ id: GameID<Factory>) -> Tooltip? {
        guard let factory: Factory = self.context.state.factories[id] else {
            return nil
        }
        return .instructions {
            $0["Growth"] = factory.grow[/0] / 100
        }
    }

    public func tooltipFactoryWorkers(
        _ id: GameID<Factory>,
        _ stratum: PopStratum,
    ) -> Tooltip? {
        guard let factory: FactoryContext = self.context.factories[id] else {
            return nil
        }

        let workforce: FactoryContext.Workforce
        let type: PopType
        let wage: (y: Int64, t: Int64)

        if case .Worker = stratum {
            workforce = factory.workers
            type = factory.type.workers.unit
            wage = (factory.state.yesterday.wu, factory.state.today.wu)
        } else {
            workforce = factory.clerks
            type = factory.type.clerks.unit
            wage = (factory.state.yesterday.cu, factory.state.today.cu)
        }

        return .instructions {
            $0[type.plural] = workforce.total[/3] / workforce.limit
            $0[>] {
                $0["Non-union workers"] = workforce.n.count[/3]
                $0["Union workers"] = workforce.u.count[/3]
                $0["On strike", -] = ??(-workforce.s.count)[/3]
            }

            $0["Today’s change", +] = +?(
                workforce.hire - workforce.fire - workforce.quit
            )[/3]

            $0[>] {
                $0["Hired", +] = +?workforce.hire[/3]
                $0["Fired", +] = ??(-workforce.fire)[/3]
                $0["Quit", +] = ??(-workforce.quit)[/3]
            }

            $0["Union wage", +] = wage.t[/3] <- wage.y
        }
    }

    public func tooltipFactoryOwnership(
        _ id: GameID<Factory>,
        culture: String,
    ) -> Tooltip? {
        guard
        let factory: FactoryContext = self.context.factories[id],
        let culture: Culture = self.context.state.cultures[culture] else {
            return nil
        }

        let (share, total): (share: Int64, total: Int64) = factory.equity.owners.reduce(
            into: (0, 0)
        ) {
            guard let pop: Pop = self.context.state.pops[$1.id] else {
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
        _ id: GameID<Factory>,
        country: GameID<Country>,
    ) -> Tooltip? {
        guard
        let factory: FactoryContext = self.context.factories[id],
        let country: Country = self.context.state.countries[country] else {
            return nil
        }

        let (share, total): (share: Int64, total: Int64) = factory.equity.owners.reduce(
            into: (0, 0)
        ) {
            guard let pop: Pop = self.context.state.pops[$1.id] else {
                return
            }
            if case country.id? = self.context.planets[pop.home]?.occupied {
                $0.share += $1.count
            }
            $0.total += $1.count
        }

        return .instructions(style: .borderless) {
            $0[country.name] = (Double.init(share) / Double.init(total))[%3]
        }
    }
}
extension GameSession {
    public func tooltipPlanetCell(_ id: GameID<Planet>, _ cell: HexCoordinate) -> Tooltip? {
        guard
        let planet: PlanetContext = self.context.planets[id],
        let cell: PlanetContext.Cell = planet.cells[cell] else {
            return nil
        }

        return .instructions(style: .borderless) {
            $0[>] = "\(cell.type.name)"
        }
    }
}
extension GameSession {
    public func tooltipPopAccount(_ id: GameID<Pop>) -> Tooltip? {
        guard let pop: Pop = self.context.state.pops[id] else {
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

    public func tooltipPopJobs(_ id: GameID<Pop>) -> Tooltip? {
        guard let pop: Pop = self.context.state.pops[id] else {
            return nil
        }

        let total: (
            count: Int64,
            hire: Int64,
            fire: Int64,
            quit: Int64
        ) = pop.jobs.values.reduce(into: (0, 0, 0, 0)) {
            $0.count += $1.employed
            $0.hire += $1.hire
            $0.fire += $1.fire
            $0.quit += $1.quit
        }

        return .instructions {
            $0["Total employment"] = total.count[/3]
            $0[>] {
                for job: FactoryJob in pop.jobs.values {
                    let change: Int64 = job.hire - job.fire - job.quit
                    let name: String = self.context.factories[job.at]?.type.name ?? "Unknown"
                    $0[name, +] = job.employed[/3] <- job.employed - change
                }
            }
            $0["Today’s change", +] = +?(total.hire - total.fire - total.quit)[/3]
            $0[>] {
                $0["Hired today", +] = +?total.hire[/3]
                $0["Fired today", +] = ??(-total.fire)[/3]
                $0["Quit today", +] = ??(-total.quit)[/3]
            }
        }
    }

    public func tooltipPopNeeds(
        _ id: GameID<Pop>,
        _ tier: ResourceNeedTier
    ) -> Tooltip? {
        guard let pop: Pop = self.context.state.pops[id] else {
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
        _ id: GameID<Pop>,
        _ tier: ResourceNeedTier,
        _ need: Resource,
    ) -> Tooltip? {
        guard let pop: PopContext = self.context.pops.table[id] else {
            return nil
        }

        let input: Quantity<Resource>?
        let stock: ResourceInput?
        let scale: Double
        switch tier {
        case .l:
            input = pop.type.l.first { $0.unit == need }
            stock = pop.state.nl.first { $0.id == need }
            scale = pop.state.needsPerCapita.l
        case .e:
            input = pop.type.e.first { $0.unit == need }
            stock = pop.state.ne.first { $0.id == need }
            scale = pop.state.needsPerCapita.e
        case .x:
            input = pop.type.x.first { $0.unit == need }
            stock = pop.state.nx.first { $0.id == need }
            scale = pop.state.needsPerCapita.x
        default:
            return nil
        }

        guard
        let input: Quantity<Resource>,
        let stock: ResourceInput else {
            return nil
        }

        return .instructions {
            $0["Consumed today", +] = stock.consumed[/3] / stock.demanded
            $0[>] {
                $0["Demand per capita"] = (scale * Double.init(input.amount))[..3]
            }
        }
    }

    public func tooltipPopStockpile(
        _ id: GameID<Pop>,
        _ tier: ResourceNeedTier,
        _ need: Resource,
    ) -> Tooltip? {
        guard let pop: PopContext = self.context.pops.table[id] else {
            return nil
        }

        let stock: ResourceInput?
        switch tier {
        case .l:
            stock = pop.state.nl.first { $0.id == need }
        case .e:
            stock = pop.state.ne.first { $0.id == need }
        case .x:
            stock = pop.state.nx.first { $0.id == need }
        default:
            return nil
        }

        guard
        let stock: ResourceInput else {
            return nil
        }

        return Self.tooltipResourceStockpile(stock)
    }

    public func tooltipPopType(
        _ id: GameID<Pop>,
    ) -> Tooltip? {
        guard
        let pop: PopContext = self.context.pops.table[id],
        let country: GameID<Country> = context.planets[pop.state.home]?.occupied,
        let country: Country = self.context.state.countries[country]
        else {
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
}
extension GameSession {
    private static func tooltipResourceStockpile(_ stock: ResourceInput) -> Tooltip? {
        .instructions {
            let change: Int64 = stock.purchased - stock.consumed

            $0["Total stockpile", +] = stock.acquired[/3] <- stock.acquired - change
            $0[>] {
                $0["Average cost"] = ??stock.averageCost[..2]
                $0["Supply (days)"] = stock.acquired == 0
                    ? nil
                    : (Double.init(stock.acquired) / Double.init(stock.demanded))[..3]
            }

            $0["Purchased today", +] = +?stock.purchased[/3]
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
        self.context.state.pops.hash(into: &hasher)
        self.context.state.factories.hash(into: &hasher)
        return hasher.finalize()
    }

    public static func != (a: borrowing Self, b: borrowing Self) -> Bool {
        a.context.state.pops != b.context.state.pops ||
        a.context.state.factories != b.context.state.factories
    }
}
#endif
