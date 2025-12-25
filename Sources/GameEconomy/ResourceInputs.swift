import Assert
import GameIDs
import OrderedCollections

@frozen public struct ResourceInputs {
    public var segmented: OrderedDictionary<Resource, ResourceInput>
    public var tradeable: OrderedDictionary<Resource, ResourceInput>
    public var tradeableDaysReserve: Int64

    @inlinable public init(
        segmented: OrderedDictionary<Resource, ResourceInput>,
        tradeable: OrderedDictionary<Resource, ResourceInput>,
        tradeableDaysReserve: Int64
    ) {
        self.segmented = segmented
        self.tradeable = tradeable
        self.tradeableDaysReserve = tradeableDaysReserve
    }
    @inlinable public static var empty: Self {
        .init(segmented: [:], tradeable: [:], tradeableDaysReserve: 0)
    }
}
extension ResourceInputs {
    @inlinable public static var stockpileDaysFactor: Int64 { 2 }
    @inlinable public var count: Int { self.segmented.count + self.tradeable.count }

    private var fulfilled: Double {
        min(
            self.segmented.values.reduce(1) { min($0, $1.fulfilled) },
            self.tradeable.values.reduce(1) { min($0, $1.fulfilled) },
        )
    }
    private var fulfilledAfterReservation: Double {
        min(
            self.segmented.values.reduce(1) { min($0, $1.fulfilled) },
            self.tradeable.values.reduce(1) { min($0, $1.fulfilledAfterReservation) },
        )
    }

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
    ) -> (Double, Bool) {
        // we need to reset this, or we won’t buy any tomorrow
        defer {
            self.tradeableDaysReserve = 0
        }
        if  self.full {
            self.consume(from: resourceTier, scalingFactor: scalingFactor, reservingDays: 1)
            return (self.fulfilled, true)
        } else {
            return (self.fulfilled, false)
        }
    }

    public mutating func consumeAmortized(
        from resourceTier: ResourceTier,
        scalingFactor: (x: Int64, z: Double),
    ) -> Double {
        self.consume(
            from: resourceTier,
            scalingFactor: scalingFactor,
            reservingDays: self.tradeableDaysReserve
        )
        if  self.tradeableDaysReserve > 0 {
            self.tradeableDaysReserve -= 1
        }
        return self.fulfilledAfterReservation
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
        stockpileDays: ResourceStockpileTarget,
        spendingLimit: Int64,
        in currency: CurrencyID,
        on exchange: inout WorldMarkets,
    ) -> TradeProceeds {
        if  self.tradeableDaysReserve > 0 {
            return .zero
        }

        let supplyDaysTarget: Int64 = Self.stockpileDaysFactor * stockpileDays.lower
        let weights: [Double] = self.tradeable.values.map {
            Double.init(
                $0.needed($0.unitsDemanded * supplyDaysTarget)
            ) * exchange.price(of: $0.id, in: currency)
        }

        return self.trade(
            stockpileDaysTarget: stockpileDays.today,
            stockpileDaysReturn: stockpileDays.upper,
            spendingLimit: spendingLimit,
            in: currency,
            on: &exchange,
            weights: weights[...]
        )
    }
    public mutating func tradeAsConsumer(
        stockpileDays: ResourceStockpileTarget,
        spendingLimit: Int64,
        in currency: CurrencyID,
        on exchange: inout WorldMarkets,
    ) -> TradeProceeds {
        if  self.tradeableDaysReserve > 0 {
            return .zero
        }

        let supplyDaysTarget: Int64 = Self.stockpileDaysFactor * stockpileDays.lower
        let weights: [Double] = self.tradeable.values.map {
            /// w = deficit / demanded * sqrt(demanded * price)
            ///   = deficit / demanded * sqrt(demanded) * sqrt(price)
            ///   = deficit / sqrt(demanded) * sqrt(price)
            ///   = deficit * sqrt(price / demanded)
            ///
            /// this can be a little counterintuitive, unless you remember that the deficit
            /// itself is proportional to demand, which makes the weight scale with the
            /// square root of demand and the square root of price.
            return Double.init($0.needed($0.unitsDemanded * supplyDaysTarget)) * .sqrt(
                exchange.price(of: $0.id, in: currency) / Double.init($0.unitsDemanded)
            )
        }

        return self.trade(
            stockpileDaysTarget: stockpileDays.today,
            stockpileDaysReturn: stockpileDays.upper,
            spendingLimit: spendingLimit,
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
                stockpileDaysTarget: Self.stockpileDaysFactor * stockpileDaysTarget,
                stockpileDaysReturn: Self.stockpileDaysFactor * stockpileDaysReturn,
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

        self.tradeableDaysReserve = stockpileDaysTarget

        return .init(gain: gain, loss: loss)
    }
}

#if TESTABLE
extension ResourceInputs: Equatable, Hashable {}
#endif
