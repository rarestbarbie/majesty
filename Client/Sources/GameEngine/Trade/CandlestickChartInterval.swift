import GameEconomy
import GameState
import JavaScriptKit
import JavaScriptInterop

struct CandlestickChartInterval {
    public let id: GameDate
    public let prices: Candle<Double>
    public let volume: Int64
}
extension CandlestickChartInterval: JavaScriptEncodable {
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
