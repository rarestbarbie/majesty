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

        js[.y] = self.yesterday
        js[.z] = self.today
        js[.b] = self.units.base
        js[.q] = self.units.quote
    }
}
extension WorldMarket.State: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            id: try js[.id].decode(),
            dividend: try js[.dividend].decode(),
            history: try js[.history].decode(),
            fee: try js[.fee].decode() ?? 0 %/ 1,
            yesterday: try js[.y].decode(),
            today: try js[.z].decode(),
            units: .init(base: try js[.b].decode(), quote: try js[.q].decode()),
        )
    }
}
