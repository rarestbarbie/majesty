import Assert
import OrderedCollections

@frozen public struct ResourceOutputs {
    public var tradeable: OrderedDictionary<Resource, TradeableOutput>
    public var inelastic: OrderedDictionary<Resource, InelasticOutput>

    @inlinable public init(
        tradeable: OrderedDictionary<Resource, TradeableOutput>,
        inelastic: OrderedDictionary<Resource, InelasticOutput>
    ) {
        self.tradeable = tradeable
        self.inelastic = inelastic
    }
    @inlinable public init() {
        self.tradeable = [:]
        self.inelastic = [:]
    }
}
extension ResourceOutputs {
    @inlinable public var count: Int { self.tradeable.count + self.inelastic.count }
}
extension ResourceOutputs {
    public mutating func sync(
        with resourceTier: ResourceTier,
        scalingFactor: (x: Int64, z: Double),
    ) {
        self.inelastic.sync(with: resourceTier.inelastic) {
            $0.turn(
                unitsProduced: $1 * scalingFactor.x,
                efficiency: scalingFactor.z
            )
        }
    }
    public mutating func deposit(
        from resourceTier: ResourceTier,
        scalingFactor: (x: Int64, z: Double),
    ) {
        self.tradeable.sync(with: resourceTier.tradeable) {
            $0.deposit(
                unitsProduced: $1 * scalingFactor.x,
                efficiency: scalingFactor.z
            )
        }
    }
}
extension ResourceOutputs {
    /// Returns the amount of funds actually received.
    public mutating func sell(
        in currency: Fiat,
        on exchange: inout Exchange,
    ) -> Int64 {
        self.tradeable.values.indices.reduce(into: 0) {
            $0 += self.tradeable.values[$1].sell(in: currency, on: &exchange)
        }
    }
}

#if TESTABLE
extension ResourceOutputs: Equatable, Hashable {}
#endif
