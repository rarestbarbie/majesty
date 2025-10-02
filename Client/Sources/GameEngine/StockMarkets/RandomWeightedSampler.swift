import Random

/// A type that can efficiently draw multiple weighted random samples from a collection.
///
/// This sampler has an O(n) initialization cost and an O(log n) cost for each
/// subsequent sample.
struct RandomWeightedSampler<Element, Weight>
    where Weight: BinaryFloatingPoint, Weight.RawSignificand: FixedWidthInteger {
    private let cumulativeWeights: [(element: Element, cumulativeWeight: Weight)]
    private let totalWeight: Weight

    /// Creates a sampler for the given collection.
    ///
    /// - Parameters:
    ///   - collection: The collection of elements to sample from.
    ///   - weight: A closure that returns the weight for a given element.
    /// - Returns: A new sampler, or `nil` if the collection is empty or the
    ///   total weight is zero.
    init?(
        choices: borrowing some Collection<Element>,
        sampleWeight: (Element) -> Weight
    ) {
        var cumulativeData: [(element: Element, cumulativeWeight: Weight)] = .init()
        ;   cumulativeData.reserveCapacity(choices.count)

        var accumulatedWeight: Weight = .zero
        for element: Element in copy choices {
            accumulatedWeight += sampleWeight(element)
            cumulativeData.append((element, accumulatedWeight))
        }

        guard
        let totalWeight: Weight = cumulativeData.last?.cumulativeWeight, totalWeight > .zero
        else {
            return nil
        }

        self.cumulativeWeights = cumulativeData
        self.totalWeight = totalWeight
    }

    /// Returns the next weighted random element.
    func next(using generator: inout some RandomNumberGenerator) -> Element {
        let randomValue: Weight = .random(in: .zero ..< self.totalWeight, using: &generator)

        // `partitioningIndex` performs a binary search to find the index.
        let index: Int = self.cumulativeWeights.partitioningIndex {
            $0.cumulativeWeight < randomValue
        }

        return self.cumulativeWeights[index].element
    }
}
