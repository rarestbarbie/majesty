import GameState
import JavaScriptKit
import JavaScriptInterop
import Vector
import VectorCharts

struct PlanetGrid {
    var cells: [PlanetGridCell]

    init() {
        self.cells = []
    }
}
extension PlanetGrid {
    mutating func update(from planet: PlanetContext, in _: GameContext) {
        self.cells = planet.grid { $0.type.color }
    }
}
extension PlanetGrid {
    enum ObjectKey: JSString, Sendable {
        case type
        case cells
    }
}
extension PlanetGrid: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.type] = PlanetDetailsTab.Grid
        js[.cells] = self.cells
    }
}
