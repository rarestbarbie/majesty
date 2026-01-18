import GameEconomy
import JavaScriptInterop

extension LocalMarkets.Settings {
    @frozen public enum ObjectKey: JSString {
        case _empty
    }
}
extension LocalMarkets.Settings: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init()
    }
}
