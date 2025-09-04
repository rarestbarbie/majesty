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
    @inlinable public mutating func trade(
        stockpileDays target: TradeableInput.StockpileTarget,
        spendingLimit budget: Int64,
        in currency: Fiat,
        on exchange: inout Exchange,
    ) -> (gain: Int64, loss: Int64) {
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

    /// Loss is negative, Gain is positive.
    @usableFromInline mutating func trade(
        stockpileDays: ClosedRange<Int64>,
        spendingLimit: Int64,
        in currency: Fiat,
        on exchange: inout Exchange,
        weights: ArraySlice<Double>,
    ) -> (gain: Int64, loss: Int64) {
        guard let budget: [Int64] = weights.distribute(spendingLimit) else {
            return (0, 0)
        }

        var gain: Int64 = 0
        var loss: Int64 = 0

        for i: Int in self.tradeable.values.indices {
            let value: Int64 = self.tradeable.values[i].trade(
                stockpileDays: stockpileDays,
                budget: budget[i],
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
            Budget: \(budget)
            """
        )

        return (gain: gain, loss: loss)
    }
}

#if TESTABLE
extension ResourceInputs: Equatable, Hashable {}
#endif
