import GameIDs
import GameRules
import JavaScriptInterop
import JavaScriptKit

@frozen public struct PopWealth {
    public let type: PopType
    public let cash: Int64
    public let race: Symbol?
}
extension PopWealth: JavaScriptDecodable {
    @frozen public enum ObjectKey: JSString {
        case type
        case cash
        case race
    }

    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            type: try js[.type].decode(),
            cash: try js[.cash].decode(),
            race: try js[.race]?.decode()
        )
    }
}
