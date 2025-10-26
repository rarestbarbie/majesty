import GameEconomy
import GameIDs
import JavaScriptKit
import JavaScriptInterop

struct ResourceSale {
    let label: ResourceLabel

    let unitsProduced: Int64
    let unitsSold: Int64
    let valueSold: Int64

    let priceAtMarket: Candle<Double>?
    let price: Candle<LocalPrice>?
}
extension ResourceSale: Identifiable {
    var id: InventoryLine { .o(self.label.id) }
}
extension ResourceSale: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case id
        case name
        case icon

        case unitsProduced
        case unitsSold
        case valueSold

        case price
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.name] = self.label.name
        js[.icon] = self.label.icon
        js[.unitsProduced] = self.unitsProduced
        js[.unitsSold] = self.unitsSold
        js[.valueSold] = self.valueSold
        js[.price] = self.priceAtMarket ?? self.price?.map { Double.init($0.value) }
    }
}
