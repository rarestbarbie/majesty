import Fraction
import GameIDs
import OrderedCollections

@frozen public struct LocalMarkets {
    // iteration order matters, because the RNG is called statefully during matching
    @usableFromInline var table: OrderedDictionary<LocalMarket.ID, LocalMarket>

    @inlinable public init(table: OrderedDictionary<LocalMarket.ID, LocalMarket>) {
        self.table = table
    }

    @inlinable public init() {
        self.init(table: [:])
    }
}
extension LocalMarkets {
    @inlinable public var markets: OrderedDictionary<LocalMarket.ID, LocalMarket> {
        self.table
    }

    @inlinable public subscript(id: LocalMarket.ID) -> LocalMarket {
        _read {
            yield  self.table[id, default: .init(id: id)]
        }
        _modify {
            yield &self.table[id, default: .init(id: id)]
        }
    }
}
extension LocalMarkets {
    public mutating func turn(by turn: (inout LocalMarket) -> ()) {
        for i: Int in self.table.elements.indices {
            turn(&self.table.values[i])
        }
    }
}
extension LocalMarkets {
    public mutating func place(
        bids tier: (
            (budget: Int64, weights: [InelasticBudgetTier.Weight]),
            (budget: Int64, weights: [InelasticBudgetTier.Weight]),
            (budget: Int64, weights: [InelasticBudgetTier.Weight])
        ),
        asks: OrderedDictionary<Resource, ResourceOutput<Never>>,
        as lei: LEI,
        in tile: Address,
    ) {
        self.bid(budget: tier.0.budget, as: lei, in: tile, tier: 0, weights: tier.0.weights)
        self.bid(budget: tier.1.budget, as: lei, in: tile, tier: 1, weights: tier.1.weights)
        self.bid(budget: tier.2.budget, as: lei, in: tile, tier: 2, weights: tier.2.weights)
        self.ask(asks: asks, as: lei, in: tile)
    }

    public mutating func ask(
        asks: OrderedDictionary<Resource, ResourceOutput<Never>>,
        memo: MineID? = nil,
        as lei: LEI,
        in tile: Address,
    ) {
        for (id, output): (Resource, ResourceOutput<Never>) in asks {
            let ask: Int64 = output.unitsReleased
            if  ask > 0 {
                self[id / tile].ask(amount: ask, by: lei, memo: memo)
            }
        }
    }

    public mutating func bid(
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
                self[x.id / tile].bid(
                    budget: budget,
                    by: lei,
                    in: tier,
                    // not `x.unitsToPurchase`!
                    // this effectively makes the stockpile target 1–2d
                    limit: x.units
                )
            }
        }
    }
}
