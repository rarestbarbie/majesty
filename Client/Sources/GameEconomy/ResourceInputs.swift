import Assert
import OrderedCollections

@frozen public struct ResourceInputs {
    public var tradeable: OrderedDictionary<Resource, TradeableInput>
    public var inelastic: OrderedDictionary<Resource, InelasticInput>

    @inlinable public init(
        tradeable: OrderedDictionary<Resource, TradeableInput>,
        inelastic: OrderedDictionary<Resource, InelasticInput>
    ) {
        self.tradeable = tradeable
        self.inelastic = inelastic
    }
    @inlinable public init() {
        self.tradeable = [:]
        self.inelastic = [:]
    }
}
extension ResourceInputs {
    @inlinable public var count: Int { self.tradeable.count + self.inelastic.count }
}
extension ResourceInputs {
    public mutating func sync(
        with resourceTier: ResourceTier,
        scalingFactor: (x: Int64, z: Double),
        stockpileDays: Int64,
    ) {
        self.tradeable.sync(with: resourceTier.tradeable) {
            $0.turn(
                unitsDemanded: $1 * scalingFactor.x,
                stockpileDays: stockpileDays,
                efficiency: scalingFactor.z
            )
        }
        self.inelastic.sync(with: resourceTier.inelastic) {
            $0.turn(
                unitsDemanded: $1 * scalingFactor.x,
                efficiency: scalingFactor.z
            )
        }
    }
    public mutating func consume(
        from resourceTier: ResourceTier,
        scalingFactor: (x: Int64, z: Double),
    ) {
        self.tradeable.sync(with: resourceTier.tradeable) {
            $0.consume($1 * scalingFactor.x, efficiency: scalingFactor.z)
        }
    }
}
extension ResourceInputs {
    /// Returns the amount of funds actually spent.
    @inlinable public mutating func buy(
        days stockpile: Int64,
        with budget: Int64,
        in currency: Fiat,
        on exchange: inout Exchange,
    ) -> Int64 {
        let weights: [Double] = self.tradeable.values.map {
            Double.init($0.needed($0.unitsCapacity)) * exchange.price(of: $0.id, in: currency)
        }

        return self.buy(
            days: stockpile,
            with: budget,
            in: currency,
            on: &exchange,
            weights: weights[...]
        )
    }

    /// Returns the amount of funds actually spent.
    @usableFromInline mutating func buy(
        days stockpile: Int64,
        with budget: Int64,
        in currency: Fiat,
        on exchange: inout Exchange,
        weights: ArraySlice<Double>,
    ) -> Int64 {
        guard let budgets: [Int64] = weights.distribute(budget) else {
            return 0
        }

        var funds: Int64 = budget

        for i: Int in self.tradeable.values.indices {
            funds -= self.tradeable.values[i].buy(
                days: stockpile,
                with: budgets[i],
                in: currency,
                on: &exchange
            )
        }

        #assert(
            0 ... budget ~= funds,
            """
            Spending is out of bounds: \(funds) not in [0, \(budget)] ?!?!
            Inputs: \(self)
            Budgets: \(budgets)
            """
        )

        return budget - funds
    }
}

#if TESTABLE
extension ResourceInputs: Equatable, Hashable {}
#endif
