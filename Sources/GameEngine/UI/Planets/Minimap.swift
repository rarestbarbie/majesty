import GameIDs
import GameState
import HexGrids
import JavaScriptInterop
import JavaScriptKit

struct Minimap: Sendable {
    let id: PlanetID
    let layer: MinimapLayer

    var name: String
    var grid: [PlanetMapTile]
    var tiles: [Address: PlanetGrid.TileSnapshot]

    init(id: PlanetID, layer: MinimapLayer) {
        self.id = id
        self.layer = layer
        self.name = ""
        self.grid = []
        self.tiles = [:]
    }
}
extension Minimap {
    mutating func update(
        in context: borrowing GameSnapshot,
        planets: RuntimeContextTable<PlanetContext>
    ) {
        guard
        let planet: PlanetContext = planets[self.id] else {
            self.grid = []
            return
        }

        self.tiles = planet.grid.tiles.values.reduce(into: [:]) { $0[$1.id] = $1.snapshot }
        self.name = planet.state.name

        switch self.layer {
        case .Terrain:
            self.grid = planet.grid.color { $0.terrain.color }

        case .Population:
            let scale: Double = .init(
                planet.grid.tiles.values.reduce(0) { max($0, $1.pops.free.total) }
            )
            self.grid = planet.grid.color {
                scale > 0 ? Double.init($0.pops.free.total) / scale : 0
            }

        case .AverageMilitancy:
            let scale: Double = .init(
                planet.grid.tiles.values.reduce(0) { max($0, $1.pops.free.total) }
            )
            self.grid = planet.grid.color {
                let (value, population): (Double, of: Double) = $0.pops.free.mil
                return (0.1 * value, population / scale)
            }

        case .AverageConsciousness:
            let scale: Double = .init(
                planet.grid.tiles.values.reduce(0) { max($0, $1.pops.free.total) }
            )
            self.grid = planet.grid.color {
                let (value, population): (Double, of: Double) = $0.pops.free.con
                return (0.1 * value, population / scale)
            }
        }
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
