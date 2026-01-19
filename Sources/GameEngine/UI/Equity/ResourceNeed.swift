import GameEconomy
import GameRules
import JavaScriptInterop

struct ResourceNeed {
    let label: ResourceLabel
    let tier: ResourceTierIdentifier

    let demanded: Int64
    let acquired: Int64
    let fulfilled: Double
    let stockpile: Double?

    let price: Candle<Double>?
}
extension ResourceNeed {
    static func progressive(
        label: ResourceLabel,
        tier: ResourceTierIdentifier,
        input: ResourceInput,
        price: Candle<Double>?,
    ) -> Self {
        let fulfilled: Double
        let stockpile: Double
        if  input.unitsDemanded > 0 {
            let denominator: Double = Double.init(input.unitsDemanded)
            fulfilled = input.units.added < input.unitsDemanded
                ? Double.init(input.units.added) / denominator
                : 1
            stockpile = input.units.total < input.unitsDemanded
                ? Double.init(input.units.total) / denominator
                : 1
        } else {
            fulfilled = 0
            stockpile = 0
        }

        return .init(
            label: label,
            tier: tier,
            demanded: input.unitsDemanded,
            acquired: input.units.total,
            fulfilled: fulfilled,
            stockpile: stockpile,
            price: price
        )
    }

    static func continuous(
        label: ResourceLabel,
        tier: ResourceTierIdentifier,
        input: ResourceInput,
        price: Candle<Double>?,
    ) -> Self {
        let fulfilled: Double
        if  input.unitsDemanded > 0 {
            let unitsConsumed: Int64 = input.unitsConsumed
            fulfilled = unitsConsumed < input.unitsDemanded
                ? Double.init(unitsConsumed) / Double.init(input.unitsDemanded)
                : 1
        } else {
            fulfilled = 0
        }

        return .init(
            label: label,
            tier: tier,
            demanded: input.unitsDemanded,
            acquired: input.units.total,
            fulfilled: fulfilled,
            stockpile: nil,
            price: price
        )
    }
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
        case demanded
        case acquired
        case fulfilled
        case stockpile
        case price
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.id] = self.id
        js[.name] = self.label.title
        js[.icon] = self.label.icon
        js[.tier] = self.tier
        js[.demanded] = self.demanded
        js[.acquired] = self.acquired
        js[.fulfilled] = self.fulfilled
        js[.stockpile] = self.stockpile
        js[.price] = self.price
    }
}
