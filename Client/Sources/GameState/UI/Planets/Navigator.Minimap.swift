import GameEngine
import JavaScriptInterop
import JavaScriptKit

extension Navigator {
    @frozen @usableFromInline struct Minimap {
        let id: GameID<Planet>
        var name: String
        var grid: [PlanetGridCell]

        init(id: GameID<Planet>) {
            self.id = id
            self.name = ""
            self.grid = []
        }
    }
}
extension Navigator.Minimap {
    mutating func update(
        in context: GameContext,
        cursor: [GameID<Planet>: HexCoordinate]
    ) -> Navigator.Tile? {
        guard
        let planet: PlanetContext = context.planets[self.id] else {
            self.grid = []
            return nil
        }

        self.name = planet.state.name
        self.grid = planet.grid

        if  let cell: HexCoordinate = cursor[planet.state.id],
            let cell: PlanetContext.Cell = planet.cells[cell] {
            return .init(
                id: cell.id,
                name: cell.tile.name,
                terrain: cell.type.name
            )

        } else {
            return nil
        }
    }
}
extension Navigator.Minimap: JavaScriptEncodable {
    @frozen @usableFromInline enum ObjectKey: JSString, Sendable {
        case id
        case name
        case grid
    }

    @usableFromInline func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.name] = self.name
        js[.grid] = self.grid
    }
}
