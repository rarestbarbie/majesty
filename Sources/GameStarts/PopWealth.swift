import GameIDs
import GameEconomy
import JavaScriptInterop
import JavaScriptKit

@frozen public struct PopWealth {
    public let type: PopType
    public let cash: Int64
    public let nat: String?
}
extension PopWealth: JavaScriptDecodable {
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
