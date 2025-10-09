import GameEconomy
import GameState

struct LocalMarkets {
    private var markets: [Key: LocalMarket]

    init(markets: [Key: LocalMarket] = [:]) {
        self.markets = markets
    }
}
extension LocalMarkets {
    subscript(location: Address, resource: Resource) -> LocalMarket {
        _read {
            yield  self.markets[.init(location: location, resource: resource), default: .init()]
        }
        _modify {
            yield &self.markets[.init(location: location, resource: resource), default: .init()]
        }
    }
}
extension LocalMarkets {
    mutating func turn(by turn: (Key, inout LocalMarket) -> ()) {
        var i: [Key: LocalMarket].Index = self.markets.startIndex
        while i < self.markets.endIndex {
            let id: Key = self.markets.keys[i]
            turn(id, &self.markets.values[i])
            i = self.markets.index(after: i)
        }
    }
}
extension LocalMarkets {
    mutating func place(
        bids tier: (
            (budget: Int64, weights: [InelasticBudgetTier.Weight]),
            (budget: Int64, weights: [InelasticBudgetTier.Weight]),
            (budget: Int64, weights: [InelasticBudgetTier.Weight])
        ),
        as lei: LEI,
        in tile: Address,
    ) {
        self.bid(budget: tier.0.budget, as: lei, in: tile, tier: 0, weights: tier.0.weights)
        self.bid(budget: tier.1.budget, as: lei, in: tile, tier: 1, weights: tier.1.weights)
        self.bid(budget: tier.2.budget, as: lei, in: tile, tier: 2, weights: tier.2.weights)
    }

    private mutating func bid(
        budget budgetTotal: Int64,
        as lei: LEI,
        in tile: Address,
        tier: UInt8,
        weights: [InelasticBudgetTier.Weight],
    ) {
        guard budgetTotal > 0,
        let budgets: [Int64] = weights.distribute(budgetTotal, share: \.value) else {
            return
        }

        for (budget, x): (Int64, InelasticBudgetTier.Weight) in zip(budgets, weights) {
            if budget > 0, x.unitsToPurchase > 0 {
                self[tile, x.id].bid(
                    budget: budget,
                    by: lei,
                    in: tier,
                    limit: x.unitsToPurchase
                )
            }
        }
    }
}
