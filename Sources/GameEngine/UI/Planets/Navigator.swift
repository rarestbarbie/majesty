import GameIDs
import GameState
import HexGrids
import JavaScriptInterop
import JavaScriptKit

public struct Navigator: Sendable {
    private var cursor: [PlanetID: HexCoordinate]

    private(set) var minimap: Minimap?
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
    mutating func select(planet: PlanetID, layer: PlanetMapLayer?) {
        self.minimap = .init(id: planet, layer: layer ?? self.minimap?.layer ?? .Terrain)
        if let saved: HexCoordinate = self.cursor[planet] {
            self.tile = .init(id: planet / saved)
        }
    }
    mutating func select(detail: Address) {
        self.cursor[detail.planet] = detail.tile
        self.tile = .init(id: detail)
    }

    mutating func update(in cache: borrowing GameUI.Cache) {
        self.minimap?.update(in: cache)
        self.tile?.update(in: cache)
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
