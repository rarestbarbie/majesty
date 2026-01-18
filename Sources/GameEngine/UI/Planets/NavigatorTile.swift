import ColorReference
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
    private var culture: PieChart<CultureID, ColorReference>?
    private var popType: PieChart<PopOccupation, ColorReference>?

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
    mutating func update(in cache: borrowing GameUI.Cache) {
        guard
        let planet: PlanetSnapshot = cache.planets[self.id.planet],
        let tile: TileSnapshot = cache.tiles[self.id] else {
            return
        }

        self.name = "\(tile.name ?? tile.metadata.ecology.title) (\(planet.state.name))"
        self.terrain = tile.metadata.ecology.title

        let pops: PopulationStats = tile.pops

        let culture: [
            (key: CultureID, (share: Int64, ColorReference))
        ] = pops.free.cultures.compactMap {
            guard let culture: Culture = cache.rules.pops.cultures[$0] else {
                return nil
            }
            let label: ColorReference = .color(culture.color)
            return ($0, ($1, label))
        }
        let popType: [
            (key: PopOccupation, (share: Int64, ColorReference))
        ] = pops.occupation.compactMap {
            guard $0.stratum > .Ward,
            let key: Legend.Representation = cache.rules.legend.occupation[$0] else {
                return nil
            }

            let label: ColorReference = .color(key.color)
            return ($0, ($1.count, label))
        }

        self._neighbors = self.id.tile.neighbors(size: planet.grid.radius)

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
