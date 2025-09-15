import GameState
import JavaScriptInterop
import JavaScriptKit

@frozen public struct PlanetSurface {
    public let id: PlanetID
    public let size: Int8
    public let grid: [Tile]

    @inlinable public init(
        id: PlanetID,
        size: Int8,
        grid: [Tile]
    ) {
        self.id = id
        self.size = size
        self.grid = grid
    }
}
extension PlanetSurface {
    @frozen public enum ObjectKey: JSString {
        case id
        case size
        case grid
    }
}
extension PlanetSurface: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.size] = self.size
        js[.grid] = self.grid
    }
}
extension PlanetSurface: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
            size: try js[.size].decode(),
            grid: try js[.grid].decode(),
        )
    }
}
