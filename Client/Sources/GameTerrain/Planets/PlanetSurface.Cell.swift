import HexGrids
import JavaScriptInterop
import JavaScriptKit

extension PlanetSurface {
    @frozen public struct Cell {
        public let id: HexCoordinate
        public let type: String
        public let tile: PlanetTile

        @inlinable public init(
            id: HexCoordinate,
            type: String,
            tile: PlanetTile,
        ) {
            self.id = id
            self.type = type
            self.tile = tile
        }
    }
}
extension PlanetSurface.Cell {
    @frozen public enum ObjectKey: JSString {
        case id
        case type
        case tile
    }
}
extension PlanetSurface.Cell: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.type] = self.type
        js[.tile] = self.tile
    }
}
extension PlanetSurface.Cell: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
            type: try js[.type].decode(),
            tile: try js[.tile]?.decode() ?? .init(),
        )
    }
}
