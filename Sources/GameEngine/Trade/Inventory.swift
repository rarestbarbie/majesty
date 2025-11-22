import Fraction
import GameEconomy
import GameIDs

struct Inventory {
    var out: ResourceOutputs
    var l: ResourceInputs
    var e: ResourceInputs
    var x: ResourceInputs
}
extension Inventory {
    init() {
        self.init(
            out: .init(),
            l: .init(),
            e: .init(),
            x: .init()
        )
    }
}
extension Inventory {
    func profit(variableCosts: Int64, fixedCosts: Int64) -> ProfitMargins {
        .init(
            variableCosts: variableCosts + self.l.valueConsumed,
            fixedCosts: fixedCosts + self.e.valueConsumed,
            revenue: self.out.valueSold
        )
    }
}
extension Inventory {
    mutating func report(resource: Resource, fill: LocalMarket.Fill, side: LocalMarket.Side) {
        switch side {
        case .sell:
            self.report(
                resourceSold: resource,
                units: fill.filled,
                value: fill.value,
            )

        case .buy:
            guard case .tier(let tier)? = fill.memo else {
                fatalError("filled buy order with no tier memo!!!")
            }

            self.report(
                resourcePurchased: resource,
                units: fill.filled,
                value: fill.value,
                tier: tier
            )
        }
    }

    private mutating func report(
        resourceSold resource: Resource,
        units: Int64,
        value: Int64,
    ) {
        self.out.segmented[resource]?.report(unitsSold: units, valueSold: value)
    }

    private mutating func report(
        resourcePurchased resource: Resource,
        units: Int64,
        value: Int64,
        tier: UInt8?
    ) {
        switch tier {
        case 0?:
            self.l.segmented[resource]?.report(
                unitsPurchased: units,
                valuePurchased: value,
            )
        case 1?:
            self.e.segmented[resource]?.report(
                unitsPurchased: units,
                valuePurchased: value,
            )
        case 2?:
            self.x.segmented[resource]?.report(
                unitsPurchased: units,
                valuePurchased: value,
            )

        case _:
            return
        }
    }
}

#if TESTABLE
extension Inventory: Equatable, Hashable {}
#endif
