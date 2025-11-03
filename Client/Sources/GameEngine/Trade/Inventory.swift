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
        price: LocalPrice
    ) -> Int64 {
        let value: Int64 = units <> price.value
        self.out.inelastic[resource]?.report(
            unitsSold: units,
            valueSold: value,
        )
        self.account.r += value
        return value
    }

    mutating func debit(
        inelastic resource: Resource,
        units: Int64,
        price: LocalPrice,
        tier: UInt8?
    ) -> Int64 {
        let value: Int64 = units >< price.value

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
            return 0
        }

        self.account.b -= value
        return value
    }
}

#if TESTABLE
extension Inventory: Equatable, Hashable {}
#endif
