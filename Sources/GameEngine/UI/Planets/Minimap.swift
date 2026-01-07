import GameIDs
import GameState
import HexGrids
import JavaScriptInterop
import JavaScriptKit

struct Minimap: Sendable {
    let id: PlanetID
    var layer: PlanetMapLayer

    var name: String
    var grid: [PlanetMapTile]

    init(id: PlanetID, layer: PlanetMapLayer) {
        self.id = id
        self.layer = layer
        self.name = ""
        self.grid = []
    }
}
extension Minimap {
    mutating func update(in cache: borrowing GameUI.Cache) {
        guard
        let tiles: PlanetSnapshot.Tiles = cache[planet: self.id] else {
            self.grid = []
            return
        }

        self.name = tiles.planet.state.name
        self.grid = tiles.color(layer: self.layer)
    }
}
extension Minimap: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case id
        case layers
        case layer
        case name
        case grid
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.layers] = PlanetMapLayer.allCases
        js[.layer] = self.layer
        js[.name] = self.name
        js[.grid] = self.grid
    }
}
