import GameClock
import GameIDs
import JavaScriptKit
import JavaScriptInterop

public struct GameUI {
    private var player: Country?
    private var date: GameDate

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
    var clock: GameClock

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
        self.clock = .init()
    }
}
extension GameUI {
    mutating func sync(with snapshot: borrowing GameSnapshot) throws {
        self.player = snapshot.playerCountry
        self.date = snapshot.date

        self.navigator.update(in: snapshot.context)

        // Only update screens that are currently open
        switch self.screen {
        case .Planet?: self.report.planet.update(from: snapshot)
        case .Infrastructure?: self.report.infrastructure.update(from: snapshot)
        case .Production?: self.report.production.update(from: snapshot)
        case .Population?: self.report.population.update(from: snapshot)
        case .Trade?: self.report.trade.update(from: snapshot)
        case nil: break
        }

        try self.views.0?.update(in: snapshot.context)
        try self.views.1?.update(in: snapshot.context)
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

        js[.speed] = self.clock.speed
        js[.views] = [self.views.0, self.views.1]
    }
}
