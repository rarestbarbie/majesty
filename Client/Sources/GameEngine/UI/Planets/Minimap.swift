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

        switch self.layer {
        case .Terrain:
            self.grid = planet.grid { $0.type.color }

        case .Population:
            let maxPopulation: Double = .init(planet.cells.values.reduce(0) {
                max($0, $1.population)
            })
            self.grid = planet.grid {
                let population: Double = .init($0.population)
                let intensity: UInt8 = maxPopulation > 0 ?
                    .init(255 * population / maxPopulation) : 0
                return .init(r: intensity, g: intensity, b: intensity)
            }

        case .AverageMilitancy:
            self.grid = planet.grid {
                guard $0.population > 0 else {
                    return 0
                }
                // Scale militancy (0-10) to a red color channel (0-255)
                let population: Double = .init($0.population)
                let militancy: UInt8 = .init(($0.weighted.mil / population) * 25.5)
                return .init(r: militancy, g: 0, b: 0)
            }

        case .AverageConsciousness:
            self.grid = planet.grid {
                guard $0.population > 0 else {
                    return 0
                }
                // Scale consciousness (0-10) to a blue color channel (0-255)
                let population: Double = .init($0.population)
                let consciousness: UInt8 = .init(($0.weighted.con / population) * 25.5)
                return .init(r: 0, g: 0, b: consciousness)
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
