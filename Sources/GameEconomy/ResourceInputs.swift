import Assert
import GameIDs
import OrderedCollections

@frozen public struct ResourceInputs {
    public var segmented: OrderedDictionary<Resource, ResourceInput>
    public var tradeable: OrderedDictionary<Resource, ResourceInput>
    public var tradeableDaysSupply: Int64

    @inlinable public init(
        segmented: OrderedDictionary<Resource, ResourceInput>,
        tradeable: OrderedDictionary<Resource, ResourceInput>,
        tradeableDaysSupply: Int64
    ) {
        self.segmented = segmented
        self.tradeable = tradeable
        self.tradeableDaysSupply = tradeableDaysSupply
    }
    @inlinable public static var empty: Self {
        .init(segmented: [:], tradeable: [:], tradeableDaysSupply: 0)
    }
}
extension ResourceInputs {
    @inlinable public var count: Int { self.segmented.count + self.tradeable.count }

    private var full: Bool {
        for input: ResourceInput in self.segmented.values where input.units.total < input.unitsDemanded {
            return false
        }
        for input: ResourceInput in self.tradeable.values where input.units.total < input.unitsDemanded {
            return false
        }
        return true
    }
}
extension ResourceInputs {
    public mutating func sync(
        with resourceTier: ResourceTier,
        scalingFactor: (x: Int64, z: Double),
    ) {
        self.segmented.sync(with: resourceTier.segmented) {
            $1.turn(unitsDemanded: $0 * scalingFactor.x, efficiency: scalingFactor.z)
        }
        self.tradeable.sync(with: resourceTier.tradeable) {
            $1.turn(unitsDemanded: $0 * scalingFactor.x, efficiency: scalingFactor.z)
        }
    }

    /// This function ignores `tradeableDaysSupply` and consumes all available resources up to
    /// the specified quantity. If this is being called, it’s highly probable that it is not
    /// being called on every turn, which makes it advisable to reset `self.tradeableDaysSupply`
    /// to zero, in order to encourage more of the resources to be purchased on the next turn.
    public mutating func consumeAvailable(
        from resourceTier: ResourceTier,
        scalingFactor: (x: Int64, z: Double),
    ) -> Bool {
        // we need to reset this, or we won’t buy any tomorrow
        defer {
            self.tradeableDaysSupply = 0
        }
        if  self.full {
            self.consume(from: resourceTier, scalingFactor: scalingFactor, reservingDays: 1)
            return true
        } else {
            return false
        }
    }

    public mutating func consumeAmortized(
        from resourceTier: ResourceTier,
        scalingFactor: (x: Int64, z: Double),
    ) {
        self.consume(
            from: resourceTier,
            scalingFactor: scalingFactor,
            reservingDays: self.tradeableDaysSupply
        )
        if  self.tradeableDaysSupply > 0 {
            self.tradeableDaysSupply -= 1
        }
    }

    private mutating func consume(
        from resourceTier: ResourceTier,
        scalingFactor: (x: Int64, z: Double),
        reservingDays: Int64
    ) {
        for (id, amount): (Resource, Int64) in resourceTier.segmented {
            self.segmented[id].consume(
                amount * scalingFactor.x,
                efficiency: scalingFactor.z,
                reservedDays: 1
            )
        }
        for (id, amount): (Resource, Int64) in resourceTier.tradeable {
            self.tradeable[id].consume(
                amount * scalingFactor.x,
                efficiency: scalingFactor.z,
                reservedDays: reservingDays
            )
        }
    }
}
extension ResourceInputs {
    /// Returns the amount of funds actually spent.
    ///
    /// The only difference between this and `tradeAsConsumer` is that this method uses
    /// linear weights rather than square-rooted weights when distributing the budget. This
    /// makes it buy even ratios of resources as a business would, rather than favoring
    /// cheaper resources as a consumer would.
    public mutating func tradeAsBusiness(
        stockpileDays target: ResourceStockpileTarget,
        spendingLimit budget: Int64,
        in currency: CurrencyID,
        on exchange: inout WorldMarkets,
    ) -> TradeProceeds {
        if  self.tradeableDaysSupply > 0 {
            return .zero
        }

        let weights: [Double] = self.tradeable.values.map {
            Double.init(
                $0.needed($0.unitsDemanded * target.lower)
            ) * exchange.price(of: $0.id, in: currency)
        }

        return self.trade(
            stockpileDaysTarget: target.today,
            stockpileDaysReturn: target.upper,
            spendingLimit: budget,
            in: currency,
            on: &exchange,
            weights: weights[...]
        )
    }
    public mutating func tradeAsConsumer(
        stockpileDays target: ResourceStockpileTarget,
        spendingLimit budget: Int64,
        in currency: CurrencyID,
        on exchange: inout WorldMarkets,
    ) -> TradeProceeds {
        if  self.tradeableDaysSupply > 0 {
            return .zero
        }

        let weights: [Double] = self.tradeable.values.map {
            Double.init(
                $0.needed($0.unitsDemanded * target.lower)
            ) * .sqrt(exchange.price(of: $0.id, in: currency))
        }

        return self.trade(
            stockpileDaysTarget: target.today,
            stockpileDaysReturn: target.upper,
            spendingLimit: budget,
            in: currency,
            on: &exchange,
            weights: weights[...]
        )
    }

    /// Loss is negative, Gain is positive.
    private mutating func trade(
        stockpileDaysTarget: Int64,
        stockpileDaysReturn: Int64,
        spendingLimit: Int64,
        in currency: CurrencyID,
        on exchange: inout WorldMarkets,
        weights: ArraySlice<Double>,
    ) -> TradeProceeds {
        /// we want to guarantee that each resource gets at least 1 unit of budget
        var reserved: Int64 = min(Int64.init(weights.count), spendingLimit)
        let budget: [Int64]? = weights.distribute(spendingLimit - reserved)

        var gain: Int64 = 0
        var loss: Int64 = 0

        for i: Int in self.tradeable.values.indices {
            var budgeted: Int64 = budget?[i] ?? 0
            if  reserved > 0 {
                reserved -= 1
                budgeted += 1
            }
            let value: Int64 = self.tradeable.values[i].trade(
                stockpileDaysTarget: stockpileDaysTarget,
                stockpileDaysReturn: stockpileDaysReturn,
                budget: budgeted,
                in: currency,
                on: &exchange
            )
            if  value > 0 {
                gain += value
            } else {
                loss += value
            }
        }

        #assert(
            0 ... spendingLimit ~= -loss,
            """
            Spending is out of bounds: \(-loss) not in [0, \(spendingLimit)] ?!?!
            Inputs: \(self)
            Budget: \(budget ?? [])
            """
        )

        self.tradeableDaysSupply = stockpileDaysTarget

        return .init(gain: gain, loss: loss)
    }
}

#if TESTABLE
extension ResourceInputs: Equatable, Hashable {}
#endif
