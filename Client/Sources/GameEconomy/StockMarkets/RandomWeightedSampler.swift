import Random

/// A type that can efficiently draw multiple weighted random samples from a collection.
///
/// This sampler has an O(n) initialization cost and an O(log n) cost for each
/// subsequent sample.
@frozen public struct RandomWeightedSampler<Choices, Weight> where Choices: Collection,
    Weight: BinaryFloatingPoint,
    Weight.RawSignificand: FixedWidthInteger {
    @usableFromInline let cumulativeWeights: [(choice: Choices.Index, cumulativeWeight: Weight)]
    @usableFromInline let totalWeight: Weight

    /// Creates a sampler for the given collection.
    ///
    /// - Parameters:
    ///   - collection: The collection of elements to sample from.
    ///   - weight: A closure that returns the weight for a given element.
    /// - Returns: A new sampler, or `nil` if the collection is empty or the
    ///   total weight is zero.
    @inlinable public init?(
        choices: borrowing Choices,
        sampleWeight: (Choices.Element) -> Weight
    ) {
        var cumulativeData: [(Choices.Index, cumulativeWeight: Weight)] = .init()
        ;   cumulativeData.reserveCapacity(choices.count)

        var accumulatedWeight: Weight = .zero
        for i: Choices.Index in choices.indices {
            accumulatedWeight += sampleWeight(choices[i])
            cumulativeData.append((i, accumulatedWeight))
        }

        guard
        let totalWeight: Weight = cumulativeData.last?.cumulativeWeight,
            totalWeight > .zero else {
            return nil
        }

        self.cumulativeWeights = cumulativeData
        self.totalWeight = totalWeight
    }

    /// Returns the next weighted random element.
    @inlinable public func next(using generator: inout some RandomNumberGenerator) -> Choices.Index {
        let randomValue: Weight = .random(in: .zero ..< self.totalWeight, using: &generator)

        // `partitioningIndex` performs a binary search to find the index.
        let index: Int = self.cumulativeWeights.partitioningIndex {
            $0.cumulativeWeight < randomValue
        }

        return self.cumulativeWeights[index].choice
    }
}
