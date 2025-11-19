import GameIDs
import GameEconomy
import JavaScriptInterop
import JavaScriptKit

@frozen public struct PopSeed {
    public let type: PopType
    public let cash: Int64
    public let nat: String?
}
extension PopSeed: JavaScriptDecodable {
    @frozen public enum ObjectKey: JSString {
        case type
        case cash
        case nat
    }

    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            type: try js[.type].decode(),
            cash: try js[.cash].decode(),
            nat: try js[.nat]?.decode()
        )
    }
}
