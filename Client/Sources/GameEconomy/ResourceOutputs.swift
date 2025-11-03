import Assert
import Fraction
import GameIDs
import OrderedCollections

@frozen public struct ResourceOutputs {
    public var tradeable: OrderedDictionary<Resource, ResourceOutput<Double>>
    public var inelastic: OrderedDictionary<Resource, ResourceOutput<Never>>

    @inlinable public init(
        tradeable: OrderedDictionary<Resource, ResourceOutput<Double>>,
        inelastic: OrderedDictionary<Resource, ResourceOutput<Never>>
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
        releasing fraction: Fraction
    ) {
        self.inelastic.sync(with: resourceTier.inelastic) {
            $0.turn(releasing: fraction) ; _ = $1
        }
        self.tradeable.sync(with: resourceTier.tradeable) {
            $0.turn(releasing: fraction) ; _ = $1
        }
    }
    public mutating func deposit(
        from resourceTier: ResourceTier,
        scalingFactor: (x: Int64, z: Double),
    ) {
        self.inelastic.sync(with: resourceTier.inelastic) {
            $0.deposit(unitsProduced: $1 * scalingFactor.x, efficiency: scalingFactor.z)
        }
        self.tradeable.sync(with: resourceTier.tradeable) {
            $0.deposit(unitsProduced: $1 * scalingFactor.x, efficiency: scalingFactor.z)
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
