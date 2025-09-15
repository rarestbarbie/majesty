import GameRules
import HexGrids
import JavaScriptInterop
import JavaScriptKit

extension PlanetSurface {
    @frozen public struct Tile {
        public let id: HexCoordinate
        public let name: String?
        public let terrain: Symbol
        public let geology: Symbol

        @inlinable public init(
            id: HexCoordinate,
            name: String?,
            terrain: Symbol,
            geology: Symbol
        ) {
            self.id = id
            self.name = name
            self.terrain = terrain
            self.geology = geology
        }
    }
}
extension PlanetSurface.Tile {
    @frozen public enum ObjectKey: JSString {
        case id
        case name
        case terrain = "type"
        case geology
    }
}
extension PlanetSurface.Tile: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.name] = self.name
        js[.terrain] = self.terrain
        js[.geology] = self.geology
    }
}
extension PlanetSurface.Tile: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
            name: try js[.name]?.decode(),
            terrain: try js[.terrain].decode(),
            geology: try js[.geology]?.decode() ?? "_None"
        )
    }
}
