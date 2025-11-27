import GameIDs
import GameEconomy
import GameRules
import JavaScriptInterop
import JavaScriptKit

@frozen public struct BuildingSeedGroup {
    public let tile: Address
    public let buildings: SymbolTable<Int64>
}
extension BuildingSeedGroup: JavaScriptDecodable {
    @frozen public enum ObjectKey: JSString {
        case tile
        case buildings
    }

    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            tile: try js[.tile].decode(),
            buildings: try js[.buildings]?.decode() ?? [:]
        )
    }
}
