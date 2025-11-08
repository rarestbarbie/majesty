import GameIDs
import HexGrids
import JavaScriptInterop
import JavaScriptKit

public struct Navigator {
    private var cursor: [PlanetID: HexCoordinate]

    private var minimap: Minimap?
    private var tile: NavigatorTile?

    init() {
        self.cursor = [:]

        self.minimap = nil
        self.tile = nil
    }
}
extension Navigator {
    var current: (planet: PlanetID?, tile: Address?) {
        (self.minimap?.id, self.tile?.id)
    }
}
extension Navigator {
    mutating func select(planet: PlanetID, layer: MinimapLayer?, cell: HexCoordinate?) {
        self.minimap = .init(id: planet, layer: layer ?? self.minimap?.layer ?? .Terrain)

        if let cell: HexCoordinate {
            self.cursor[planet] = cell
            self.tile = .init(id: .init(planet: planet, tile: cell))
        } else if let saved: HexCoordinate = self.cursor[planet] {
            self.tile = .init(id: .init(planet: planet, tile: saved))
        }
    }

    mutating func update(in context: GameContext) {
        self.minimap?.update(in: context)
        self.tile?.update(in: context)
    }
}
extension Navigator: JavaScriptEncodable {
    @frozen public enum ObjectKey: JSString, Sendable {
        case minimap
        case tile
    }

    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.minimap] = self.minimap
        js[.tile] = self.tile
    }
}
