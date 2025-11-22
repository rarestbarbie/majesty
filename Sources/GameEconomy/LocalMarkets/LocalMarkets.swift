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
    public mutating func trade(
        selling: OrderedDictionary<Resource, ResourceOutput>,
        buying tier: (
            (budget: Int64, weights: [SegmentedBudgetTier.Weight]),
            (budget: Int64, weights: [SegmentedBudgetTier.Weight]),
            (budget: Int64, weights: [SegmentedBudgetTier.Weight])
        ),
        as lei: LEI,
        in tile: Address,
    ) {
        self.buy(
            budget: tier.0.budget,
            entity: lei,
            memo: .tier(0),
            tile: tile,
            weights: tier.0.weights
        )
        self.buy(
            budget: tier.1.budget,
            entity: lei,
            memo: .tier(1),
            tile: tile,
            weights: tier.1.weights
        )
        self.buy(
            budget: tier.2.budget,
            entity: lei,
            memo: .tier(2),
            tile: tile,
            weights: tier.2.weights
        )
        self.sell(supply: selling, entity: lei, tile: tile)
    }

    public mutating func sell(
        supply: OrderedDictionary<Resource, ResourceOutput>,
        entity: LEI,
        memo: LocalMarket.Memo? = nil,
        tile: Address,
    ) {
        for (id, output): (Resource, ResourceOutput) in supply {
            let units: Int64 = output.unitsReleased
            if  units > 0 {
                self[id / tile].sell(amount: units, entity: entity, memo: memo)
            }
        }
    }

    public mutating func buy(
        budget budgetTotal: Int64,
        entity: LEI,
        memo: LocalMarket.Memo? = nil,
        tile: Address,
        weights: [SegmentedBudgetTier.Weight],
    ) {
        guard budgetTotal > 0,
        let budgets: [Int64] = weights.distribute(budgetTotal, share: \.value) else {
            return
        }

        for (budget, x): (Int64, SegmentedBudgetTier.Weight) in zip(budgets, weights) {
            if budget > 0, x.unitsToPurchase > 0 {
                self[x.id / tile].buy(
                    budget: budget,
                    entity: entity,
                    // not `x.unitsToPurchase`!
                    //
                    // why do we do it this way? some resource tiers (like the expansion tier)
                    // are “progress like”, that is, it takes multiple days to fill them up to
                    // 100 percent. if we set the limit to `x.unitsToPurchase`, then they would
                    // have “hiccups” every time the meter passes the 100 percent mark and turns
                    // over to zero again.
                    //
                    // this effectively makes the stockpile target 1–2d. it won’t cause us to
                    // accumulate absurd amounts of resources, because we still condition
                    // purchases on `x.unitsToPurchase > 0` above.
                    limit: x.units,
                    memo: memo,
                )
            }
        }
    }
}
