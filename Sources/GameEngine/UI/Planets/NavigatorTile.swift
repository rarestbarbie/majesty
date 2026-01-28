import ColorReference
import GameIDs
import GameRules
import HexGrids
import JavaScriptInterop
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

        let culture: [
            (key: CultureID, (share: Int64, ColorReference))
        ] = cache.rules.pops.cultures.compactMap {
            guard
            let metrics: EconomicLedger.CapitalMetrics = cache.context.ledger.z.economy.racial[
                self.id / $0
            ] else {
                return nil
            }
            let label: ColorReference = .color($1.color)
            return ($0, (metrics.count, label))
        }
        let popType: [
            (key: PopOccupation, (share: Int64, ColorReference))
        ] = PopOccupation.allCases.compactMap {
            guard
            let row: EconomicLedger.LaborMetrics = cache.context.ledger.z.economy.labor[
                self.id / $0
            ],
            let key: Legend.Representation = cache.rules.legend.occupation[$0] else {
                return nil
            }

            let label: ColorReference = .color(key.color)
            return ($0, (row.count, label))
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
