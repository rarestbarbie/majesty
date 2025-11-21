import Assert
import Fraction
import GameIDs
import OrderedCollections

@frozen public struct ResourceOutputs {
    public var tradeable: OrderedDictionary<Resource, ResourceOutput>
    public var inelastic: OrderedDictionary<Resource, ResourceOutput>

    @inlinable public init(
        tradeable: OrderedDictionary<Resource, ResourceOutput>,
        inelastic: OrderedDictionary<Resource, ResourceOutput>
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
            $1.turn(releasing: fraction)
        }
        self.tradeable.sync(with: resourceTier.tradeable) {
            $1.turn(releasing: fraction)
        }
    }
    public mutating func deposit(
        from resourceTier: ResourceTier,
        scalingFactor: (x: Int64, z: Double),
    ) {
        for (id, amount): (Resource, Int64) in resourceTier.inelastic {
            self.inelastic[id].deposit(amount * scalingFactor.x, efficiency: scalingFactor.z)
        }
        for (id, amount): (Resource, Int64) in resourceTier.tradeable {
            self.tradeable[id].deposit(amount * scalingFactor.x, efficiency: scalingFactor.z)
        }
    }
}
extension ResourceOutputs {
    /// Returns the amount of funds actually received.
    public mutating func sell(
        in currency: CurrencyID,
        on exchange: inout BlocMarkets,
    ) -> Int64 {
        self.tradeable.values.indices.reduce(into: 0) {
            $0 += self.tradeable.values[$1].sell(in: currency, on: &exchange)
        }
    }
}

#if TESTABLE
extension ResourceOutputs: Equatable, Hashable {}
#endif
