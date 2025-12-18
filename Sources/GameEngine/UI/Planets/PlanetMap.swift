import GameState
import JavaScriptKit
import JavaScriptInterop
import Vector
import VectorCharts

struct PlanetMap {
    var tiles: [PlanetMapTile]

    init() {
        self.tiles = []
    }
}
extension PlanetMap {
    mutating func update(from planet: PlanetContext, in _: borrowing GameSnapshot) {
        self.tiles = planet.grid.color(\.terrain.color)
    }
}
extension PlanetMap {
    enum ObjectKey: JSString, Sendable {
        case type
        case tiles
    }
}
extension PlanetMap: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.type] = PlanetDetailsTab.Grid
        js[.tiles] = self.tiles
    }
}
