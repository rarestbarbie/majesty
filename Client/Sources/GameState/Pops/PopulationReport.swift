import GameEngine
import JavaScriptKit
import JavaScriptInterop

public struct PopulationReport {
    private var pops: [PopTableEntry]
    private var pop: PopDetails?

    init() {
        self.pops = []
        self.pop = nil
    }
}
extension PopulationReport: PersistentReport {
    mutating func select(subject: GameID<Pop>?, details: Never?, filter: Never?) {
        if  let subject: GameID<Pop> {
            self.pop = .init(id: subject)
        }
    }

    mutating func update(on map: borrowing GameMap, in context: GameContext) {
        self.pops.removeAll()

        guard
        let country: CountryContext = context.countries[context.player] else {
            return
        }

        let include: Set<GameID<Planet>> = .init(country.state.territory)
        for pop: PopContext in context.pops.table where include.contains(
            pop.state.home.planet
        ) {
            guard
            let location: Planet = context.state.planets[pop.state.home.planet],
            let culture: Culture = context.state.cultures[pop.state.nat] else {
                continue
            }

            self.pops.append(.init(
                id: pop.state.id,
                location: location.name,
                type: pop.state.type,
                color: culture.color,
                nat: pop.state.nat,
                une: pop.unemployment,
                yesterday: pop.state.yesterday,
                today: pop.state.today,
                jobs: pop.state.jobs.values.map {
                    .init(
                        name: context.factories[$0.at]?.type.name ?? "Unknown",
                        size: $0.employed,
                        hire: $0.hire,
                        fire: $0.fire,
                        quit: $0.quit,
                    )
                },
                cash: pop.state.cash,
            ))
        }

        self.pop?.update(in: context)
    }
}
extension PopulationReport {
    @frozen public enum ObjectKey: JSString, Sendable {
        case type
        case pops
        case pop
    }
}
extension PopulationReport: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.type] = GameUI.ScreenType.Population
        js[.pops] = self.pops
        js[.pop] = self.pop
    }
}
