import GameState
import GameTerrain
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
    mutating func select(
        subject: PopID?,
        details: PopDetailsTab?,
        filter: Never?
    ) {
        if  let subject: PopID {
            self.pop = .init(id: subject, open: self.pop?.open ?? .Inventory)
        }
        if  let details: PopDetailsTab {
            self.pop?.open = details
        }
    }

    mutating func update(from snapshot: borrowing GameSnapshot) {
        self.pops.removeAll()

        guard
        let country: CountryContext = snapshot.countries[snapshot.player] else {
            return
        }

        for pop: PopContext in snapshot.pops {
            guard case country.state.id? = pop.governedBy?.id else {
                continue
            }

            guard
            let planet: PlanetContext = snapshot.planets[pop.state.home.planet],
            let tile: PlanetGrid.Tile = planet.grid.tiles[pop.state.home.tile],
            let culture: Culture = snapshot.cultures.state[pop.state.nat] else {
                continue
            }

            self.pops.append(
                .init(
                    id: pop.state.id,
                    location: tile.name ?? planet.state.name,
                    type: pop.state.type,
                    color: culture.color,
                    nat: pop.state.nat,
                    une: pop.unemployment,
                    yesterday: pop.state.yesterday,
                    today: pop.state.today,
                    jobs: pop.state.jobs.values.map {
                        .init(
                            name: snapshot.factories[$0.at]?.type.name ?? "Unknown",
                            size: $0.count,
                            hire: $0.hired,
                            fire: $0.fired,
                            quit: $0.quit,
                        )
                    },
                )
            )
        }

        self.pop?.update(from: snapshot)
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
