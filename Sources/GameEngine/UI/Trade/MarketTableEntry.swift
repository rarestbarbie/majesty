import GameEconomy
import JavaScriptInterop

struct MarketTableEntry: Identifiable {
    let id: WorldMarket.ID
    let name: String
    let price: Candle<Double>
    let volume: Int64
}
extension MarketTableEntry: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case id
        case name
        case price
        case volume
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.name] = self.name
        js[.price] = self.price
        js[.volume] = self.volume
    }
}
