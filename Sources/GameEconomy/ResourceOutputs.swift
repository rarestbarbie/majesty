import Assert
import Fraction
import GameIDs
import OrderedCollections
import Random

@frozen public struct ResourceOutputs {
    public var tradeableDaysReserve: Int64
    @usableFromInline var outputs: OrderedDictionary<Resource, ResourceOutput>
    @usableFromInline var outputsPartition: Int

    @inlinable public init(
        tradeableDaysReserve: Int64,
        outputs: OrderedDictionary<Resource, ResourceOutput>,
        outputsPartition: Int
    ) {
        self.tradeableDaysReserve = tradeableDaysReserve
        self.outputs = outputs
        self.outputsPartition = outputsPartition
    }
}
extension ResourceOutputs {
    @inlinable public static var empty: Self {
        .init(tradeableDaysReserve: 0, outputs: [:], outputsPartition: 0)
    }

    @inlinable public init(
        segmented: [ResourceOutput],
        tradeable: [ResourceOutput],
        tradeableDaysReserve: Int64,
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
        self.init(tradeableDaysReserve: tradeableDaysReserve, outputs: combined, outputsPartition: outputsPartition)
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
    @inlinable public var joined: ResourceStockpileCollection<ResourceOutput> {
        .init(elements: self.all, elementsPartition: self.outputsPartition)
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
                sold = Double.init($1.unitsSold %/ $1.units.removed)
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
    ) {
        self.outputsPartition = resourceTier.i
        self.outputs.sync(with: resourceTier.x) { $1.turn() }
    }
    public mutating func produce(
        from resourceTier: ResourceTier,
        scalingFactor: (x: Int64, z: Double),
    ) {
        for i: Int in self.segmented.indices {
            // we are relying on the indexing guarantee from `sync`
            let x: Int64 = resourceTier[i].amount
            self.outputs.values[i].produce(x * scalingFactor.x, efficiency: scalingFactor.z)
        }
        for i: Int in self.tradeable.indices {
            let x: Int64 = resourceTier[i].amount
            self.outputs.values[i].deposit(x * scalingFactor.x, efficiency: scalingFactor.z)
        }
    }
}
extension ResourceOutputs {
    /// Sell all of the stockpiled resource, returning the amount of funds actually received.
    public mutating func sell(
        in currency: CurrencyID,
        to exchange: inout WorldMarkets,
    ) -> Int64 {
        self.tradeableDaysReserve = 0
        return self.tradeable.indices.reduce(into: 0) {
            $0 += self.outputs.values[$1].sell(in: currency, to: &exchange)
        }
    }
    /// Sell a uniformly-distributed random amount of the stockpiled resource, returning the
    /// amount of funds actually received.
    public mutating func sell(
        in currency: CurrencyID,
        to exchange: inout WorldMarkets,
        random: inout PseudoRandom
    ) -> Int64 {
        self.tradeableDaysReserve = 0
        return self.tradeable.indices.reduce(into: 0) {
            $0 += self.outputs.values[$1].sell(in: currency, to: &exchange, random: &random)
        }
    }
    /// Mark the value of all stockpiled goods to the theoretical market value at the last
    /// traded price, or the market mid price if there is no last traded price.
    public mutating func mark(
        in currency: CurrencyID,
        to exchange: borrowing WorldMarkets,
    ) {
        self.tradeableDaysReserve += 1
        for i: Int in self.tradeable.indices {
            self.outputs.values[i].mark(in: currency, to: exchange)
        }
    }
}

#if TESTABLE
extension ResourceOutputs: Equatable {}
#endif
