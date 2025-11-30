import GameIDs
import GameEconomy
import GameRules
import JavaScriptInterop
import JavaScriptKit

@frozen public struct FactorySeedGroup {
    public let tile: Address
    public let factories: SymbolTable<Int64>
}
extension FactorySeedGroup: JavaScriptDecodable {
    @frozen public enum ObjectKey: JSString {
        case tile
        case factories
    }

    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            tile: try js[.tile].decode(),
            factories: try js[.factories]?.decode() ?? [:]
        )
    }
}
