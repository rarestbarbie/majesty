import Fraction
import GameEconomy
import GameIDs

struct Inventory {
    var account: Bank.Account
    var out: ResourceOutputs
    var l: ResourceInputs
    var e: ResourceInputs
    var x: ResourceInputs
}
extension Inventory {
    init() {
        self.init(
            account: .init(),
            out: .init(),
            l: .init(),
            e: .init(),
            x: .init()
        )
    }
}
extension Inventory {
    mutating func report(resource: Resource, fill: LocalMarket.Fill, side: LocalMarket.Side) {
        switch side {
        case .sell:
            self.credit(
                inelastic: resource,
                units: fill.filled,
                value: fill.value
            )

        case .buy:
            guard case .tier(let tier)? = fill.memo else {
                fatalError("filled buy order with no tier memo!!!")
            }

            self.debit(
                inelastic: resource,
                units: fill.filled,
                value: fill.value,
                tier: tier
            )
        }
    }

    private mutating func credit(
        inelastic resource: Resource,
        units: Int64,
        value: Int64
    ) {
        self.account.r += value
        self.out.inelastic[resource]?.report(unitsSold: units, valueSold: value)
    }

    private mutating func debit(
        inelastic resource: Resource,
        units: Int64,
        value: Int64,
        tier: UInt8?
    ) {
        switch tier {
        case 0?:
            self.l.inelastic[resource]?.report(
                unitsPurchased: units,
                valuePurchased: value,
            )
        case 1?:
            self.e.inelastic[resource]?.report(
                unitsPurchased: units,
                valuePurchased: value,
            )
        case 2?:
            self.x.inelastic[resource]?.report(
                unitsPurchased: units,
                valuePurchased: value,
            )

        case _:
            return
        }

        self.account.b -= value
    }
}

#if TESTABLE
extension Inventory: Equatable, Hashable {}
#endif
