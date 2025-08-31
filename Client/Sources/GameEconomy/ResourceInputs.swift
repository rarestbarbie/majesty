import Assert

@frozen public struct ResourceInputs {
    public var tradeable: [TradeableInput]
    public var inelastic: [InelasticInput]

    @inlinable public init(tradeable: [TradeableInput], inelastic: [InelasticInput]) {
        self.tradeable = tradeable
        self.inelastic = inelastic
    }
    @inlinable public init() {
        self.tradeable = []
        self.inelastic = []
    }
}
extension ResourceInputs {
    @inlinable public var count: Int { self.tradeable.count + self.inelastic.count }
}
extension ResourceInputs {
    /// Returns the amount of funds actually spent.
    @inlinable public mutating func buy(
        days stockpile: Int64,
        with budget: Int64,
        in currency: Fiat,
        on exchange: inout Exchange,
    ) -> Int64 {
        let weights: [Double] = self.tradeable.map {
            Double.init($0.needed($0.capacity)) * exchange.price(of: $0.id, in: currency)
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

        for i: Int in self.tradeable.indices {
            funds -= self.tradeable[i].buy(
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
