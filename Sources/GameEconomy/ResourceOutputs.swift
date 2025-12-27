import Assert
import Fraction
import GameIDs
import OrderedCollections

@frozen public struct ResourceOutputs {
    @usableFromInline var outputs: OrderedDictionary<Resource, ResourceOutput>
    @usableFromInline var outputsPartition: Int

    @inlinable public init(
        outputs: OrderedDictionary<Resource, ResourceOutput>,
        outputsPartition: Int
    ) {
        self.outputs = outputs
        self.outputsPartition = outputsPartition
    }
}
extension ResourceOutputs {
    @inlinable public static var empty: Self {
        .init(outputs: [:], outputsPartition: 0)
    }

    @inlinable public init(
        segmented: [ResourceOutput],
        tradeable: [ResourceOutput],
    ) {
        var combined: OrderedDictionary<Resource, ResourceOutput> = .init(
            minimumCapacity: segmented.count + tradeable.count
        )
        for output: ResourceOutput in segmented {
            combined[output.id] = output
        }
        let outputsPartition: Int = combined.elements.endIndex
        for output: ResourceOutput in tradeable {
            combined[output.id] = output
        }
        self.init(outputs: combined, outputsPartition: outputsPartition)
    }
}
extension ResourceOutputs {
    @inlinable public var count: Int { self.outputs.count }
    @inlinable public var all: [ResourceOutput] { self.outputs.values.elements }

    @inlinable public var segmented: ArraySlice<ResourceOutput> {
        self.outputs.values.elements[..<self.outputsPartition]
    }
    @inlinable public var tradeable: ArraySlice<ResourceOutput> {
        self.outputs.values.elements[self.outputsPartition...]
    }
    /// Returns the utilization of the most utilized **segmented** resource output, or `nil` if
    /// there are no segmented outputs.
    ///
    /// Utilization for tradeable outputs is not meaningful, because it is almost always
    /// possible to dump excess tradeable goods onto the market.
    @inlinable public var utilization: Double? {
        self.segmented.isEmpty ? nil : self.segmented.reduce(0) {
            let sold: Double
            if  $1.unitsSold < $1.units.removed {
                // implies `units.removed > 0`
                sold = Double.init($1.unitsSold) / Double.init($1.units.removed)
            } else {
                sold = 1
            }
            return max($0, sold)
        }
    }
}
extension ResourceOutputs {
    @inlinable public subscript(id: Resource) -> ResourceOutput? {
        _read   { yield  self.outputs[id] }
        _modify { yield &self.outputs[id] }
    }
}
extension ResourceOutputs {
    public mutating func sync(
        with resourceTier: ResourceTier,
        releasing fraction: Fraction
    ) {
        self.outputs.sync(with: resourceTier.x) {
            $1.turn(releasing: fraction)
        }
    }
    public mutating func deposit(
        from resourceTier: ResourceTier,
        scalingFactor: (x: Int64, z: Double),
    ) {
        for (id, amount): (Resource, Int64) in resourceTier {
            self.outputs[id].deposit(amount * scalingFactor.x, efficiency: scalingFactor.z)
        }
    }
}
extension ResourceOutputs {
    /// Returns the amount of funds actually received.
    public mutating func sell(
        in currency: CurrencyID,
        on exchange: inout WorldMarkets,
    ) -> Int64 {
        self.tradeable.indices.reduce(into: 0) {
            $0 += self.outputs.values[$1].sell(in: currency, on: &exchange)
        }
    }
}

#if TESTABLE
extension ResourceOutputs: Equatable, Hashable {}
#endif
