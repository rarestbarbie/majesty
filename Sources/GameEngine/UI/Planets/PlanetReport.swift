import GameIDs
import GameState
import JavaScriptKit
import JavaScriptInterop

public struct PlanetReport: Sendable {
    private var selection: PersistentExclusiveSelection<PlanetID, PlanetDetails.Focus>
    private var details: PlanetDetails?
    private var entries: [PlanetMapTile]
    private var filters: ([FilterLabel], [Never])

    private var planet: PlanetSnapshot?

    init() {
        self.selection = .init(defaultFocus: .init(layer: .Terrain))
        self.details = nil
        self.filters = ([], [])
        self.entries = []

        self.planet = nil
    }
}
extension PlanetReport: PersistentReport {
    mutating func select(request: PlanetReportRequest) {
        self.selection.select(request.subject, filter: request.filter)
        self.selection.layer = request.details
    }

    mutating func update(from cache: borrowing GameUI.Cache) {
        let player: Country = cache.playerCountry
        let bloc: Country.ID = player.suzerain ?? player.id

        let filterable: (
            planets: [PlanetID: FilterLabel],
            Never?
        ) = cache.tiles.values.reduce(into: ([:], nil)) {
            let id: PlanetID = $1.id.planet
            if case bloc? = $1.country?.bloc {
                {
                    if  case nil = $0,
                        let planet: PlanetSnapshot = cache.planets[id] {
                        $0 = .planet(planet.state.name, id)
                    }
                } (&$0.planets[id])
            }
        }

        self.filters.0 = filterable.planets.values.sorted { $0.id < $1.id }

        self.selection.filter {
            self.filters.0.first?.id
        }
        guard
        let id: PlanetID = self.selection.filter,
        let tiles: PlanetSnapshot.Tiles = cache[planet: id] else {
            return
        }

        self.entries = tiles.color(layer: self.selection.layer)
        self.planet = cache.planets[id]

        self.selection.update(
            objects: cache.tiles,
            entries: self.entries,
            details: &self.details
        ) {
            $0.update(from: $2, in: cache)
        }
    }
}
extension PlanetReport {
    @frozen public enum ObjectKey: JSString, Sendable {
        case type
        case details
        case entries

        case filter
        case filterlist
        case filterlists

        case name
        case layers
    }
}
extension PlanetReport: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.type] = GameUI.ScreenType.Planet
        js[.details] = self.details
        js[.entries] = self.entries
        // currently there is only one filterlist in the sidebar
        js[.filter] = self.selection.filter
        js[.filterlist] = 0
        js[.filterlists] = [self.filters.0]

        js[.name] = self.planet?.state.name
        js[.layers] = PlanetMapLayer.allCases
    }
}
