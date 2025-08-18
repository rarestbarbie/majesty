import HexGrids
import JavaScriptInterop
import JavaScriptKit
import VectorCharts

struct NavigatorTile {
    let id: Address

    private var name: String
    private var terrain: String
    private var culture: PieChart<String, PieChartLabel>?

    init(id: Address) {
        self.id = id
        self.name = ""
        self.terrain = ""
        self.culture = nil
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

        let (_, culture): (
            _: Never?,
            culture: [String: (share: Int64, PieChartLabel)]
        ) = cell.pops.reduce(
            into: (nil, [:])
        ) {
            guard let pop: Pop = context.state.pops[$1] else {
                return
            }

            if  let culture: Culture = context.state.cultures[pop.nat] {
                let label: PieChartLabel = .init(color: culture.color, name: culture.id)
                $0.culture[culture.id, default: (0, label)].share += pop.today.size
            }
        }

        self.culture = .init(
            values: culture.sorted { $0.key < $1.key }
        )
    }
}
extension NavigatorTile: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case id
        case name
        case terrain
        case culture
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.name] = self.name
        js[.terrain] = self.terrain
        js[.culture] = self.culture
    }
}
