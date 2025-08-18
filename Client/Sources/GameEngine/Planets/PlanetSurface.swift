import GameState
import JavaScriptInterop
import JavaScriptKit

@frozen public struct PlanetSurface {
    let id: GameID<Planet>
    let size: Int8
    let grid: [Cell]
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
