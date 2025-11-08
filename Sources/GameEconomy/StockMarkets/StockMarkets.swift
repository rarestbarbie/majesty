import GameIDs
import Random
import OrderedCollections

@frozen public struct StockMarkets {
    // iteration order currently does not matter, but it might in the future
    @usableFromInline var regions: OrderedDictionary<Fiat, StockMarket>

    @inlinable public init() {
        self.regions = [:]
    }
}
extension StockMarkets {
    private mutating func turn(by turn: (Fiat, inout StockMarket) -> ()) {
        for i: Int in self.regions.elements.indices {
            let id: Fiat = self.regions.keys[i]
            turn(id, &self.regions.values[i])
        }
    }

    public mutating func turn(
        random: inout PseudoRandom,
        execute: (inout PseudoRandom, Fiat, StockMarket.Fill) -> ()
    ) {
        self.turn { (currency: Fiat, market: inout StockMarket) in
            market.match(random: &random) { execute(&$0, currency, $1) }
        }
    }
}
extension StockMarkets {
    public mutating func queueRandomPurchase(buyer: LEI, value: Int64, currency: Fiat) {
        guard value > 0 else {
            return
        }
        self.regions[currency, default: .init()].buyers.append(
            .init(buyer: buyer, value: value)
        )
    }

    public mutating func issueShares(
        currency: Fiat,
        quantity: Int64,
        security: StockMarket.Security
    ) {
        self.regions[currency, default: .init()].assets.append(
            .init(security: security, issuable: quantity)
        )
    }
}
