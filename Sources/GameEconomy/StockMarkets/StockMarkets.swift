import GameIDs
import Random
import OrderedCollections

@frozen public struct StockMarkets {
    // iteration order currently does not matter, but it might in the future
    @usableFromInline var regions: OrderedDictionary<CurrencyID, StockMarket>

    @inlinable public init() {
        self.regions = [:]
    }
}
extension StockMarkets {
    @inlinable public mutating func turn(by turn: (inout StockMarket) -> ()) {
        for i: Int in self.regions.elements.indices {
            turn(&self.regions.values[i])
        }
    }
}
extension StockMarkets {
    public mutating func queueRandomPurchase(buyer: LEI, value: Int64, currency: CurrencyID) {
        guard value > 0 else {
            return
        }
        self.regions[currency, default: .init(id: currency)].buyers.append(
            .init(buyer: buyer, value: value)
        )
    }

    public mutating func issueShares(
        currency: CurrencyID,
        quantity: Int64,
        security: StockMarket.Security
    ) {
        self.regions[currency, default: .init(id: currency)].assets.append(
            .init(security: security, issuable: quantity)
        )
    }
}
