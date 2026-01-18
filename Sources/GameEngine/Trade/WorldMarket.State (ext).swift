import Fraction
import GameEconomy
import JavaScriptInterop

extension WorldMarket.State {
    @frozen public enum ObjectKey: JSString, Sendable {
        case id
        case history

        case y
        case z
        case b
        case q
    }
}
extension WorldMarket.State: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.history] = self.history
        js[.y] = self.y
        js[.z] = self.z
    }
}
extension WorldMarket.State: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
            history: try js[.history].decode(),
            y: try js[.y].decode(),
            z: try js[.z].decode(),
        )
    }
}
