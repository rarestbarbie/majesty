import GameClock
import GameIDs
import JavaScriptInterop

public struct GameUI: Sendable {
    var player: Country?
    var date: GameDate

    var navigator: Navigator
    var screen: ScreenType?
    var report: (
        planet: PlanetReport,
        infrastructure: InfrastructureReport,
        production: ProductionReport,
        population: PopulationReport,
        trade: TradeReport
    )
    var views: (CelestialView?, CelestialView?)
    var speed: GameSpeed

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
            .init(),
        )
        self.views = (nil, nil)
        self.speed = .init()
    }
}
extension GameUI {
    mutating func sync(with state: borrowing Cache) throws {
        self.player = state.context.playerCountry
        self.speed = state.speed
        self.date = state.date

        self.navigator.update(in: state)

        // Only update screens that are currently open
        switch self.screen {
        case .Planet?:
            self.report.planet.update(from: state)
        case .Infrastructure?:
            self.report.infrastructure.update(from: state)
        case .Production?:
            self.report.production.update(from: state)
        case .Population?:
            self.report.population.update(from: state)
        case .Trade?:
            self.report.trade.update(from: state)
        case nil:
            break
        }

        try self.views.0?.update(in: state)
        try self.views.1?.update(in: state)
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
        case .Planet?: js[.screen] = self.report.planet
        case .Infrastructure?: js[.screen] = self.report.infrastructure
        case .Production?: js[.screen] = self.report.production
        case .Population?: js[.screen] = self.report.population
        case .Trade?: js[.screen] = self.report.trade
        case nil: break
        }

        js[.speed] = self.speed
        js[.views] = [self.views.0, self.views.1]
    }
}
