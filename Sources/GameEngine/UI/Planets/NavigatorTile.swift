import GameIDs
import GameRules
import HexGrids
import JavaScriptInterop
import JavaScriptKit
import VectorCharts

struct NavigatorTile: Sendable {
    let id: Address

    private var _neighbors: [HexCoordinate]

    private var name: String
    private var terrain: String
    private var culture: PieChart<CultureID, PieChartLabel>?
    private var popType: PieChart<PopOccupation, PieChartLabel>?

    init(id: Address) {
        self.id = id
        self.name = ""
        self.terrain = ""
        self.culture = nil
        self.popType = nil

        self._neighbors = []
    }
}
extension NavigatorTile {
    mutating func update(in context: GameContext) {
        guard
        let planet: PlanetContext = context.planets[self.id.planet],
        let tile: PlanetGrid.Tile = planet.grid.tiles[self.id.tile] else {
            return
        }

        self.name = "\(tile.name ?? tile.terrain.title) (\(planet.state.name))"
        self.terrain = tile.terrain.title

        let pops: PopulationStats = tile.pops

        let culture: [
            (key: CultureID, (share: Int64, PieChartLabel))
        ] = pops.free.cultures.compactMap {
            guard let culture: Culture = context.rules.pops.cultures[$0] else {
                return nil
            }
            let label: PieChartLabel = .init(color: culture.color, name: culture.name)
            return ($0, ($1, label))
        }
        let popType: [
            (key: PopOccupation, (share: Int64, PieChartLabel))
        ] = pops.occupation.compactMap {
            guard $0.stratum > .Ward,
            let key: Legend.Representation = context.rules.legend.occupation[$0] else {
                return nil
            }

            let label: PieChartLabel = .init(color: key.color, name: $0.singular)
            return ($0, ($1.count, label))
        }

        self._neighbors = self.id.tile.neighbors(size: planet.grid.size)

        self.culture = .init(values: culture.sorted { $0.key < $1.key })
        self.popType = .init(values: popType.sorted { $0.key > $1.key })
    }
}
extension NavigatorTile: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case id
        case name
        case terrain
        case culture
        case popType

        case _neighbors
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.name] = self.name
        js[.terrain] = self.terrain
        js[.culture] = self.culture
        js[.popType] = self.popType

        js[._neighbors] = self._neighbors
    }
}
