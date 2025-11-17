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
    mutating func credit(
        inelastic resource: Resource,
        units: Int64,
        value: Int64
    ) -> Bool {
        self.account.r += value
        if case ()? = self.out.inelastic[resource]?.report(
                unitsSold: units,
                valueSold: value,
            ) {
            return true
        } else {
            return false
        }
    }

    mutating func debit(
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
