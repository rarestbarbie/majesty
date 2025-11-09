import GameEconomy
import JavaScriptKit
import JavaScriptInterop

extension LocalMarket.Interval {
    @frozen public enum ObjectKey: JSString, Sendable {
        case p
        case s
        case d
    }
}
extension LocalMarket.Interval: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.p] = self.price
        js[.s] = self.supply
        js[.d] = self.demand
    }
}
extension LocalMarket.Interval: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            price: try js[.p].decode(),
            supply: try js[.s].decode(),
            demand: try js[.d].decode()
        )
    }
}
