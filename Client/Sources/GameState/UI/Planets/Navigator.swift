import GameEngine
import JavaScriptInterop
import JavaScriptKit

@frozen public struct Navigator {
    private var cursor: [GameID<Planet>: HexCoordinate]
    private var planet: Minimap?
    private var tile: Tile?

    init() {
        self.cursor = [:]
        self.planet = nil
        self.tile = nil
    }
}
extension Navigator {
    var current: (planet: GameID<Planet>, cell: HexCoordinate?)? {
        self.planet.map { ($0.id, self.tile?.id)  }
    }
}
extension Navigator {
    mutating func select(planet: GameID<Planet>, cell: HexCoordinate?) {
        self.planet = .init(id: planet)

        if let cell: HexCoordinate {
            self.cursor[planet] = cell
        }
    }

    mutating func update(in context: GameContext) {
        self.tile = self.planet?.update(in: context, cursor: self.cursor)
    }
}
extension Navigator: JavaScriptEncodable {
    @frozen public enum ObjectKey: JSString, Sendable {
        case planet
        case tile
    }

    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.planet] = self.planet
        js[.tile] = self.tile
    }
}
