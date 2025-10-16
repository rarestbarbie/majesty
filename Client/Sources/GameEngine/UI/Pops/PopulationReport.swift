import GameIDs
import GameTerrain
import JavaScriptKit
import JavaScriptInterop

public struct PopulationReport {
    private var selection: PersistentSelection<Filter, PopDetailsTab>

    private var filters: ([FilterLabel], [Never])
    private var pops: [PopTableEntry]
    private var pop: PopDetails?

    init() {
        self.selection = .init(defaultTab: .Inventory)
        self.filters = ([], [])
        self.pops = []
        self.pop = nil
    }
}
extension PopulationReport: PersistentReport {
    mutating func select(
        subject: PopID?,
        details: PopDetailsTab?,
        filter: Filter?
    ) {
        self.selection.select(subject, detailsTab: details)
        if  let filter: Filter {
            self.selection.filter(filter)
        }
    }

    mutating func update(from snapshot: borrowing GameSnapshot) {
        self.pops.removeAll()

        let country: CountryProperties = snapshot.player

        let filterlists: (
            location: [Address: FilterLabel],
            Never?
        ) = snapshot.pops.reduce(into: ([:], nil)) {
            let tile: Address = $1.state.home
            if case country.id? = $1.governedBy?.id {
                {
                    $0 = $0 ?? snapshot.planets[tile].map { .location($0.name ?? "?", tile) }
                } (&$0.location[$1.state.home])
            }
        }

        self.selection.rebuild(
            filtering: snapshot.pops,
            entries: &self.pops,
            details: &self.pop,
            default: .all
        ) {
            guard case country.id? = $0.governedBy?.id else {
                return nil
            }
            guard
            let planet: PlanetContext = snapshot.planets[$0.state.home.planet],
            let tile: PlanetGrid.Tile = planet.grid.tiles[$0.state.home.tile],
            let culture: Culture = snapshot.cultures.state[$0.state.nat] else {
                return nil
            }

            return PopTableEntry.init(
                id: $0.state.id,
                location: tile.name ?? planet.state.name,
                type: $0.state.type,
                color: culture.color,
                nat: $0.state.nat,
                une: $0.unemployment,
                yesterday: $0.state.yesterday,
                today: $0.state.today,
                jobs: $0.state.jobs.values.map {
                    .init(
                        name: snapshot.factories[$0.at]?.type.name ?? "Unknown",
                        size: $0.count,
                        hire: $0.hired,
                        fire: $0.fired,
                        quit: $0.quit,
                    )
                },
            )
        } update: {
            $0.update(to: $2, from: snapshot)
        }

        self.filters.0 = [.all] + filterlists.location.values.sorted()
    }
}
extension PopulationReport {
    @frozen public enum ObjectKey: JSString, Sendable {
        case type
        case pops
        case pop

        case filter
        case filterlist
        case filterlists
    }
}
extension PopulationReport: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.type] = GameUI.ScreenType.Population
        js[.pops] = self.pops
        js[.pop] = self.pop

        js[.filter] = self.selection.filter

        switch self.selection.filter {
        case nil: break
        case .all?: js[.filterlist] = 0
        case .location?: js[.filterlist] = 0
        }

        js[.filterlists] = [self.filters.0]
    }
}
