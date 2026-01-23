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
            out: .empty,
            l: .empty,
            e: .empty,
            x: .empty
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
        self.out[resource]?.report(unitsSold: units, valueSold: value)
    }

    private mutating func report(
        resourcePurchased resource: Resource,
        units: Int64,
        value: Int64,
        tier: UInt8?
    ) {
        var units: Int64 = units
        var value: Int64 = value

        switch tier {
        case 0?:
            self.l[resource]?.report(
                unitsPurchased: units,
                valuePurchased: value,
            )
        case 1?:
            self.l[resource]?.capture(
                unitsPurchased: &units,
                valuePurchased: &value,
            )
            self.e[resource]?.report(
                unitsPurchased: units,
                valuePurchased: value,
            )
        case 2?:
            self.l[resource]?.capture(
                unitsPurchased: &units,
                valuePurchased: &value,
            )
            self.e[resource]?.capture(
                unitsPurchased: &units,
                valuePurchased: &value,
            )
            self.x[resource]?.report(
                unitsPurchased: units,
                valuePurchased: value,
            )

        case _:
            return
        }
    }
}

#if TESTABLE
extension Inventory: Equatable {}
#endif
