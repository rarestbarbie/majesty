import GameEconomy
import GameRules
import JavaScriptKit
import JavaScriptInterop

struct ResourceNeed {
    let label: ResourceLabel
    let tier: ResourceTierIdentifier

    let stockpile: Int64?
    let filled: Int64
    let demand: Int64
    let price: Candle<Double>?
}
extension ResourceNeed: Identifiable {
    var id: InventoryLine {
        switch self.tier {
        case .l: .l(self.label.id)
        case .e: .e(self.label.id)
        case .x: .x(self.label.id)
        }
    }
}
extension ResourceNeed: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case id
        case name
        case icon
        case tier
        case stockpile
        case filled
        case demand
        case price
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.name] = self.label.name
        js[.icon] = self.label.icon
        js[.tier] = self.tier
        js[.stockpile] = self.stockpile
        js[.filled] = self.filled
        js[.demand] = self.demand
        js[.price] = self.price
    }
}
