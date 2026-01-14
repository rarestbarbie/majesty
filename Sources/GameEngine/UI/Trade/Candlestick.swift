import GameEconomy
import GameIDs
import JavaScriptKit
import JavaScriptInterop

struct Candlestick {
    let id: GameDate
    let prices: Candle<Double>
    let volume: Int64
}
extension Candlestick: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case id
        case c
        case v
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.c] = self.prices
        js[.v] = self.volume
    }
}
