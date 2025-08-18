import GameState
import HexGrids
import JavaScriptInterop
import JavaScriptKit

struct Minimap {
    let id: GameID<Planet>
    var name: String
    var grid: [PlanetGridCell]

    init(id: GameID<Planet>) {
        self.id = id
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
        self.grid = planet.grid
    }
}
extension Minimap: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case id
        case name
        case grid
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.name] = self.name
        js[.grid] = self.grid
    }
}
