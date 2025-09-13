import GameRules
import HexGrids
import JavaScriptInterop
import JavaScriptKit
import VectorCharts

struct NavigatorTile {
    let id: Address

    private var _neighbors: [HexCoordinate]

    private var name: String
    private var terrain: String
    private var culture: PieChart<String, PieChartLabel>?
    private var popType: PieChart<PopType, PieChartLabel>?

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
        let cell: PlanetContext.Cell = planet.cells[self.id.tile] else {
            return
        }

        self.name = "\(cell.tile.name ?? cell.type.name) (\(planet.state.name))"
        self.terrain = cell.type.name

        let (culture, popType): (
            [String: (share: Int64, PieChartLabel)],
            [PopType: (share: Int64, PieChartLabel)]
        ) = cell.pops.reduce(
            into: (culture: [:], popType: [:])
        ) {
            guard
            let pop: PopContext = context.pops.table[$1] else {
                return
            }

            if  let culture: Culture = context.cultures.state[pop.state.nat] {
                let label: PieChartLabel = .init(color: culture.color, name: culture.id)
                $0.culture[culture.id, default: (0, label)].share += pop.state.today.size
            }
            do {
                let label: PieChartLabel = .init(color: pop.type.color, name: pop.type.singular)
                $0.popType[pop.state.type, default: (0, label)].share += pop.state.today.size
            }
        }

        self._neighbors = self.id.tile.neighbors(size: planet.size)

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
