import GameEconomy
import GameEngine
import JavaScriptKit
import JavaScriptInterop

struct MarketTableEntry {
    let id: Market.AssetPair
    let name: String
    let price: Candle<Double>
    let liq: (base: Int64, quote: Int64)
}
extension MarketTableEntry: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case id
        case name
        case price
        case liq_base
        case liq_quote
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.name] = self.name
        js[.price] = self.price
        js[.liq_base] = self.liq.base
        js[.liq_quote] = self.liq.quote
    }
}
