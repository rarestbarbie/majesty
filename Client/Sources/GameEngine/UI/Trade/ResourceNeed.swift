import GameEconomy
import GameRules
import JavaScriptKit
import JavaScriptInterop

struct ResourceNeed {
    let label: ResourceLabel
    let tier: ResourceTierIdentifier

    let unitsAcquired: Int64?
    let unitsConsumed: Int64
    let unitsDemanded: Int64

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
        case unitsConsumed
        case unitsDemanded
        case priceAtMarket
        case price
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.label.id
        js[.name] = self.label.name
        js[.icon] = self.label.icon
        js[.tier] = self.tier
        js[.unitsAcquired] = self.unitsAcquired
        js[.unitsConsumed] = self.unitsConsumed
        js[.unitsDemanded] = self.unitsDemanded
        js[.priceAtMarket] = self.priceAtMarket
        js[.price] = self.price
    }
}
