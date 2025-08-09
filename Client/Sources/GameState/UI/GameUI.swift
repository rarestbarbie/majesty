import GameEngine
import JavaScriptKit
import JavaScriptInterop

@frozen public struct GameUI {
    private var player: Country?
    private var date: GameDate

    var navigator: Navigator
    var screen: ScreenType?
    var report: (
        planet: PlanetReport,
        production: ProductionReport,
        population: PopulationReport,
        trade: TradeReport
    )
    var views: (CelestialView?, CelestialView?)
    var clock: Clock

    init() {
        self.player = nil
        self.date = .gregorian(year: 0, month: 1, day: 1)

        self.navigator = .init()
        self.screen = nil
        self.report = (
            .init(),
            .init(),
            .init(),
            .init(),
        )
        self.views = (nil, nil)
        self.clock = .init()
    }
}
extension GameUI {
    mutating func sync(with map: borrowing GameMap, in context: GameContext) throws {
        self.player = context.state.countries[context.state.player]
        self.date = context.date

        self.navigator.update(in: context)

        // Only update screens that are currently open
        switch self.screen {
        case .Planet?:      self.report.planet.update(on: map, in: context)
        case .Production?:  self.report.production.update(on: map, in: context)
        case .Population?:  self.report.population.update(on: map, in: context)
        case .Trade?:       self.report.trade.update(on: map, in: context)
        case nil:           break
        }

        try self.views.0?.update(in: context)
        try self.views.1?.update(in: context)
    }
}
extension GameUI {
    @frozen public enum ObjectKey: JSString, Sendable {
        case date
        case player

        case navigator
        case screen

        case speed
        case views
    }
}
extension GameUI: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.date] = self.date
        js[.player] = self.player

        js[.navigator] = self.navigator

        switch self.screen {
        case .Planet?:      js[.screen] = self.report.planet
        case .Production?:  js[.screen] = self.report.production
        case .Population?:  js[.screen] = self.report.population
        case .Trade?:       js[.screen] = self.report.trade
        case nil:           break
        }

        js[.speed] = self.clock.speed
        js[.views] = [self.views.0, self.views.1]
    }
}
