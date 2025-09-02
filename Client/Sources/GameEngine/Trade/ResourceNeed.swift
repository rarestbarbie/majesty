import GameEconomy
import GameRules
import JavaScriptKit
import JavaScriptInterop

struct ResourceNeed {
    let label: ResourceLabel
    let tier: ResourceTierIdentifier

    let unitsAcquired: Int64?
    let unitsCapacity: Int64?
    let unitsDemanded: Int64
    let unitsConsumed: Int64

    let priceAtMarket: Candle<Double>?
    let price: Candle<Int64>?
}
extension ResourceNeed: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case id
        case name
        case icon
        case tier
        case unitsAcquired
        case unitsCapacity
        case unitsDemanded
        case unitsConsumed
        case priceAtMarket
        case price
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.label.id
        js[.name] = self.label.name
        js[.icon] = self.label.icon
        js[.tier] = self.tier
        js[.unitsAcquired] = self.unitsAcquired
        js[.unitsCapacity] = self.unitsCapacity
        js[.unitsDemanded] = self.unitsDemanded
        js[.unitsConsumed] = self.unitsConsumed
        js[.priceAtMarket] = self.priceAtMarket
        js[.price] = self.price
    }
}
