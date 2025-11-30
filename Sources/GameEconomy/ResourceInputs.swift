import Assert
import GameIDs
import OrderedCollections

@frozen public struct ResourceInputs {
    public var segmented: OrderedDictionary<Resource, ResourceInput>
    public var tradeable: OrderedDictionary<Resource, ResourceInput>

    @inlinable public init(
        segmented: OrderedDictionary<Resource, ResourceInput>,
        tradeable: OrderedDictionary<Resource, ResourceInput>,
    ) {
        self.segmented = segmented
        self.tradeable = tradeable
    }
    @inlinable public static var empty: Self { .init(segmented: [:], tradeable: [:]) }
}
extension ResourceInputs {
    @inlinable public var count: Int { self.segmented.count + self.tradeable.count }
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
    public mutating func consume(
        from resourceTier: ResourceTier,
        scalingFactor: (x: Int64, z: Double),
    ) {
        for (id, amount): (Resource, Int64) in resourceTier.segmented {
            self.segmented[id].consume(amount * scalingFactor.x, efficiency: scalingFactor.z)
        }
        for (id, amount): (Resource, Int64) in resourceTier.tradeable {
            self.tradeable[id].consume(amount * scalingFactor.x, efficiency: scalingFactor.z)
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
        let weights: [Double] = self.tradeable.values.map {
            Double.init(
                $0.needed($0.unitsDemanded * target.lower)
            ) * exchange.price(of: $0.id, in: currency)
        }

        return self.trade(
            stockpileDays: target.today ... target.upper,
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
        let weights: [Double] = self.tradeable.values.map {
            Double.init(
                $0.needed($0.unitsDemanded * target.lower)
            ) * .sqrt(exchange.price(of: $0.id, in: currency))
        }

        return self.trade(
            stockpileDays: target.today ... target.upper,
            spendingLimit: budget,
            in: currency,
            on: &exchange,
            weights: weights[...]
        )
    }

    /// Loss is negative, Gain is positive.
    private mutating func trade(
        stockpileDays: ClosedRange<Int64>,
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
                stockpileDays: stockpileDays,
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

        return .init(gain: gain, loss: loss)
    }
}

#if TESTABLE
extension ResourceInputs: Equatable, Hashable {}
#endif
