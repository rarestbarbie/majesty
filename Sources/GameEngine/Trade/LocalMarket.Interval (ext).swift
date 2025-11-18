import GameEconomy
import JavaScriptKit
import JavaScriptInterop

extension LocalMarket.Interval {
    @frozen public enum ObjectKey: JSString, Sendable {
        case b
        case a
        case s
        case d
    }
}
extension LocalMarket.Interval: JavaScriptEncodable {
    public func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.b] = self.bid
        js[.a] = self.ask
        js[.s] = self.supply
        js[.d] = self.demand
    }
}
extension LocalMarket.Interval: JavaScriptDecodable {
    public init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            bid: try js[.b].decode(),
            ask: try js[.a].decode(),
            supply: try js[.s].decode(),
            demand: try js[.d].decode()
        )
    }
}
