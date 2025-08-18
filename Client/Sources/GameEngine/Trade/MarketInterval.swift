import GameEconomy
import GameState
import JavaScriptKit
import JavaScriptInterop

struct MarketInterval {
    public let id: GameDate
    public let candle: Candle<Double>
}
extension MarketInterval: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case id
        case c
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.c] = self.candle
    }
}
