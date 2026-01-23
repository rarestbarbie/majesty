import Assert
import GameIDs
import OrderedCollections

@frozen public struct ResourceInputs {
    public var tradeableDaysReserve: Int64
    @usableFromInline var inputs: OrderedDictionary<Resource, ResourceInput>
    /// The index of the first **tradeable** resource in ``inputs``, which may be the end
    /// index if there are no tradeable resources.
    @usableFromInline var inputsPartition: Int

    @inlinable public init(
        tradeableDaysReserve: Int64,
        inputs: OrderedDictionary<Resource, ResourceInput>,
        inputsPartition: Int
    ) {
        self.tradeableDaysReserve = tradeableDaysReserve
        self.inputs = inputs
        self.inputsPartition = inputsPartition
    }
}
extension ResourceInputs {
    @inlinable public static var empty: Self {
        .init(tradeableDaysReserve: 0, inputs: [:], inputsPartition: 0)
    }

    @inlinable public init(
        segmented: [ResourceInput],
        tradeable: [ResourceInput],
        tradeableDaysReserve: Int64
    ) {
        var combined: OrderedDictionary<Resource, ResourceInput> = .init(
            minimumCapacity: segmented.count + tradeable.count
        )
        for input: ResourceInput in segmented {
            combined[input.id] = input
        }
        let inputsPartition: Int = combined.elements.endIndex
        for input: ResourceInput in tradeable {
            combined[input.id] = input
        }
        self.init(
            tradeableDaysReserve: tradeableDaysReserve,
            inputs: combined,
            inputsPartition: inputsPartition
        )
    }
}
extension ResourceInputs {
    @inlinable public static var stockpileDaysFactor: Int64 { 2 }

    @inlinable public var count: Int { self.inputs.count }
    @inlinable public var all: [ResourceInput] { self.inputs.values.elements }

    @inlinable public var segmented: ArraySlice<ResourceInput> {
        self.inputs.values.elements[..<self.inputsPartition]
    }
    @inlinable public var tradeable: ArraySlice<ResourceInput> {
        self.inputs.values.elements[self.inputsPartition...]
    }
    @inlinable public var joined: ResourceStockpileCollection<ResourceInput> {
        .init(elements: self.all, elementsPartition: self.inputsPartition)
    }

    private var fulfilled: Double {
        self.inputs.values.reduce(1) { min($0, $1.fulfilled) }
    }
    private var fulfilledAfterReservation: Double {
        min(
            self.segmented.reduce(1) { min($0, $1.fulfilled) },
            self.tradeable.reduce(1) { min($0, $1.fulfilledAfterReservation) },
        )
    }

    private var full: Bool {
        for input: ResourceInput in self.inputs.values where
            input.units.total < input.unitsDemanded {
            return false
        }
        return true
    }
}
extension ResourceInputs {
    @inlinable public subscript(id: Resource) -> ResourceInput? {
        _read   { yield  self.inputs[id] }
        _modify { yield &self.inputs[id] }
    }
}
extension ResourceInputs {
    public mutating func sync(
        with resourceTier: ResourceTier,
        scalingFactor: (x: Int64, z: Double),
    ) {
        self.inputsPartition = resourceTier.i
        self.inputs.sync(with: resourceTier.x) {
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
            self.inputs[id].consume(
                amount * scalingFactor.x,
                efficiency: scalingFactor.z,
                reservedDays: 1
            )
        }
        for (id, amount): (Resource, Int64) in resourceTier.tradeable {
            self.inputs[id].consume(
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
        let weights: [Double] = self.tradeable.map {
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
        let weights: [Double] = self.tradeable.map {
            /// w = deficit / demanded * sqrt(demanded * price)
            ///   = deficit / sqrt(price * demanded / demanded²)
            ///   = deficit / sqrt(price / demanded)
            ///
            /// this can be a little counterintuitive, unless you remember that the deficit
            /// itself is proportional to demand, which makes the weight scale with the
            /// square root of demand and the square root of price.
            Double.init($0.needed($0.unitsDemanded * supplyDaysTarget)) * .sqrt(
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
        /// the budget is a regular array, so we need to index it from zero, not whatever the
        /// slice of weights starts at
        for (i, j): (Int, Int) in zip(self.tradeable.indices, 0...) {
            var budgeted: Int64 = budget?[j] ?? 0
            if  reserved > 0 {
                reserved -= 1
                budgeted += 1
            }
            let value: Int64 = self.inputs.values[i].trade(
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
extension ResourceInputs: Equatable {}
#endif
