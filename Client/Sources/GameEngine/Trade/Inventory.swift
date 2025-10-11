import Fraction
import GameEconomy
import GameIDs

struct Inventory {
    var account: CashAccount
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
    mutating func bid(in tile: Address, as lei: LEI, on map: inout GameMap) {
        for (id, output): (Resource, InelasticOutput) in self.out.inelastic {
            let ask: Int64 = output.unitsProduced
            if  ask > 0 {
                map.localMarkets[tile, id].ask(amount: ask, by: lei)
            }
        }
    }

    mutating func credit(
        inelastic resource: Resource,
        units: Int64,
        price: LocalPrice
    ) -> Int64 {
        let value: Int64 = units <> price.exact
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
        let value: Int64 = units >< price.exact

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
