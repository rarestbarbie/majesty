import GameState
import HexGrids
import JavaScriptInterop
import JavaScriptKit

struct Minimap {
    let id: PlanetID
    let layer: MinimapLayer

    var name: String
    var grid: [PlanetGridCell]

    init(id: PlanetID, layer: MinimapLayer) {
        self.id = id
        self.layer = layer
        self.name = ""
        self.grid = []
    }
}
extension Minimap {
    mutating func update(in context: GameContext) {
        guard
        let planet: PlanetContext = context.planets[self.id] else {
            self.grid = []
            return
        }

        self.name = planet.state.name
        self.grid = planet.grid { $0.type.color }
    }
}
extension Minimap: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case id
        case layer
        case name
        case grid
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.layer] = self.layer
        js[.name] = self.name
        js[.grid] = self.grid
    }
}
