import GameIDs
import GameEconomy
import JavaScriptInterop
import JavaScriptKit

@frozen public struct FactorySeed {
    public let tile: Address
    private let size: SymbolTable<Int64>
}
extension FactorySeed {
    public func unpack(symbols: GameSaveSymbols) throws -> [Quantity<FactoryType>] {
        try self.size.quantities(keys: symbols.factories)
    }
}
extension FactorySeed: JavaScriptDecodable {
    @frozen public enum ObjectKey: JSString {
        case tile
        case size
    }

    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            tile: try js[.tile].decode(),
            size: try js[.size]?.decode() ?? [:]
        )
    }
}
