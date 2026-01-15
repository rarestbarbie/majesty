import GameRules
import HexGrids
import JavaScriptInterop
import JavaScriptKit

@frozen public struct Terrain {
    public let id: HexCoordinate
    public let name: String?
    public let ecology: Symbol
    public let geology: Symbol

    @inlinable public init(
        id: HexCoordinate,
        name: String?,
        ecology: Symbol,
        geology: Symbol
    ) {
        self.id = id
        self.name = name
        self.ecology = ecology
        self.geology = geology
    }
}
extension Terrain {
    @frozen public enum ObjectKey: JSString {
        case id
        case name
        case ecology = "type"
        case geology
    }
}
extension Terrain: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.name] = self.name
        js[.ecology] = self.ecology
        js[.geology] = self.geology
    }
}
extension Terrain: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
            name: try js[.name]?.decode(),
            ecology: try js[.ecology].decode(),
            geology: try js[.geology]?.decode() ?? "_None"
        )
    }
}
