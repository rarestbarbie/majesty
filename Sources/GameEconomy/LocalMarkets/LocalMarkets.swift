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
    public mutating func tradeAsConsumer(
        selling supply: ArraySlice<ResourceOutput>,
        buying demands: SegmentedWeights<ElasticDemand>,
        budget: (l: Int64, e: Int64, x: Int64),
        as lei: LEI,
        in tile: Address
    ) {
        self.trade(
            selling: supply,
            weights: demands,
            budget: budget,
            as: lei,
            in: tile,
            progressive: (true, true, x: true)
        )
    }
    public mutating func tradeAsBusiness(
        selling supply: ArraySlice<ResourceOutput>,
        buying demands: SegmentedWeights<InelasticDemand>,
        budget: (l: Int64, e: Int64, x: Int64),
        as lei: LEI,
        in tile: Address
    ) {
        self.trade(
            selling: supply,
            weights: demands,
            budget: budget,
            as: lei,
            in: tile,
            progressive: (true, true, x: true)
        )
    }

    public mutating func sell(
        supply: ArraySlice<ResourceOutput>,
        entity: LEI,
        memo: LocalMarket.Memo? = nil,
        tile: Address,
    ) {
        for output: ResourceOutput in supply {
            let units: Int64 = output.unitsReleased
            if  units > 0 {
                self[output.id / tile].sell(amount: units, entity: entity, memo: memo)
            }
        }
    }
}
extension LocalMarkets {
    private mutating func trade(
        selling: ArraySlice<ResourceOutput>,
        weights: SegmentedWeights<InelasticDemand>,
        budget: (l: Int64, e: Int64, x: Int64),
        as lei: LEI,
        in tile: Address,
        progressive: (l: Bool, e: Bool, x: Bool)
    ) {
        self.trade(
            selling: selling,
            weights: weights,
            budget: budget,
            as: lei,
            in: tile,
            progressive: progressive
        ) {
            // no keypath, compiler optimization bug
            $0.distribute($1, share: { $0.weight })
        }
    }
    private mutating func trade(
        selling: ArraySlice<ResourceOutput>,
        weights: SegmentedWeights<ElasticDemand>,
        budget: (l: Int64, e: Int64, x: Int64),
        as lei: LEI,
        in tile: Address,
        progressive: (l: Bool, e: Bool, x: Bool)
    ) {
        self.trade(
            selling: selling,
            weights: weights,
            budget: budget,
            as: lei,
            in: tile,
            progressive: progressive
        ) {
            // no keypath, compiler optimization bug
            $0.distribute($1, share: { $0.weight })
        }
    }
    private mutating func trade<Demand>(
        selling: ArraySlice<ResourceOutput>,
        weights: SegmentedWeights<Demand>,
        budget: (l: Int64, e: Int64, x: Int64),
        as lei: LEI,
        in tile: Address,
        progressive: (l: Bool, e: Bool, x: Bool),
        distribute: ([Demand], Int64) -> [Int64]?
    ) where Demand: SegmentedDemand {
        self.buy(
            budget: budget.0,
            entity: lei,
            memo: .tier(0),
            tile: tile,
            demands: weights.l.demands,
            progressive: progressive.0,
            distribute: distribute
        )
        self.buy(
            budget: budget.1,
            entity: lei,
            memo: .tier(1),
            tile: tile,
            demands: weights.e.demands,
            progressive: progressive.1,
            distribute: distribute
        )
        self.buy(
            budget: budget.2,
            entity: lei,
            memo: .tier(2),
            tile: tile,
            demands: weights.x.demands,
            progressive: progressive.2,
            distribute: distribute
        )
        self.sell(supply: selling, entity: lei, tile: tile)
    }

    private mutating func buy<Demand>(
        budget budgetTotal: Int64,
        entity: LEI,
        memo: LocalMarket.Memo? = nil,
        tile: Address,
        demands: [Demand],
        progressive: Bool,
        distribute: ([Demand], Int64) -> [Int64]?
    ) where Demand: SegmentedDemand {
        guard budgetTotal > 0,
        let budgets: [Int64] = distribute(demands, budgetTotal) else {
            return
        }

        for (budget, demand): (Int64, Demand) in zip(budgets, demands) {
            if budget > 0, demand.unitsToPurchase > 0 {
                self[demand.id / tile].buy(
                    budget: budget,
                    entity: entity,
                    // not `demand.unitsToPurchase`!
                    //
                    // why do we do it this way? some resource tiers (like the expansion tier)
                    // are “progress like”, that is, it takes multiple days to fill them up to
                    // 100 percent. if we set the limit to `unitsToPurchase`, then they would
                    // have “hiccups” every time the meter passes the 100 percent mark and turns
                    // over to zero again.
                    //
                    // this effectively makes the stockpile target 1–2d. it won’t cause us to
                    // accumulate absurd amounts of resources, because we still condition
                    // purchases on `x.unitsToPurchase > 0` above.
                    limit: progressive ? demand.units : demand.unitsToPurchase,
                    memo: memo,
                )
            }
        }
    }
}
