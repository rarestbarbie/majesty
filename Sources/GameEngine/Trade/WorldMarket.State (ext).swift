import Fraction
import GameEconomy
import JavaScriptKit
import JavaScriptInterop

extension WorldMarket.State {
    @frozen public enum ObjectKey: JSString, Sendable {
        case id
        case dividend
        case history
        case fee

        case y
        case z
        case b
        case q
    }
}
extension WorldMarket.State: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.dividend] = self.dividend
        js[.history] = self.history
        js[.fee] = self.fee

        js[.y] = self.y
        js[.z] = self.z
    }
}
extension WorldMarket.State: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
            dividend: try js[.dividend].decode(),
            history: try js[.history].decode(),
            fee: try js[.fee].decode() ?? 0 %/ 1,
            y: try js[.y].decode(),
            z: try js[.z].decode(),
        )
    }
}
