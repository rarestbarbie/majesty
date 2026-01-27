import GameEconomy
import Testing

@Suite
struct MedianTests {
    @Test
    func ReturnsNilForEmptyInput() {
        let data: [(count: Int64, value: Double)] = []
        let median: Double? = data.medianAssumingAscendingOrder()

        #expect(median == nil)
    }

    @Test
    func ReturnsNilForZeroCount() {
        // Even if buckets exist, if the total count is 0, it is effectively empty.
        let data: [(count: Int64, value: Double)] = [
            (count: 0, value: 1.0),
            (count: 0, value: 5.0)
        ]
        let median: Double? = data.medianAssumingAscendingOrder()

        #expect(median == nil)
    }

    @Test
    func SingleBucketOddCount() {
        // [5.0, 5.0, 5.0] -> Median is 5.0
        let data: [(count: Int64, value: Double)] = [(count: 3, value: 5.0)]
        let median: Double? = data.medianAssumingAscendingOrder()

        #expect(median == 5.0)
    }

    @Test
    func SingleBucketEvenCount() {
        // [5.0, 5.0, 5.0, 5.0] -> Median is (5.0 + 5.0) / 2 = 5.0
        let data: [(count: Int64, value: Double)] = [(count: 4, value: 5.0)]
        let median: Double? = data.medianAssumingAscendingOrder()

        #expect(median == 5.0)
    }

    @Test
    func TwoBucketsEvenSplit() {
        // [2.0, 4.0] -> Median is (2.0 + 4.0) / 2 = 3.0
        let data: [(count: Int64, value: Double)] = [
            (count: 1, value: 2.0),
            (count: 1, value: 4.0)
        ]
        let median: Double? = data.medianAssumingAscendingOrder()

        #expect(median == 3.0)
    }

    @Test
    func TwoBucketsUnevenOddTotal() {
        // [2.0, 4.0, 4.0] -> Median is 4.0
        let data: [(count: Int64, value: Double)] = [
            (count: 1, value: 2.0),
            (count: 2, value: 4.0)
        ]
        let median: Double? = data.medianAssumingAscendingOrder()

        #expect(median == 4.0)
    }

    @Test
    func ThreeBucketsEvenTotalCrossBoundary() {
        // [10, 20, 20, 30] -> Total 4. Indices 1, 2.
        // Index 1 is 20.0, Index 2 is 20.0. Average 20.0.
        let data: [(count: Int64, value: Double)] = [
            (count: 1, value: 10.0),
            (count: 2, value: 20.0),
            (count: 1, value: 30.0)
        ]
        let median: Double? = data.medianAssumingAscendingOrder()

        #expect(median == 20.0)
    }

    @Test
    func DistinctBucketsForEvenMedian() {
        // [10, 10, 20, 20] -> Total 4. Indices 1 (10.0) and 2 (20.0).
        // Median = (10 + 20) / 2 = 15.0
        let data: [(count: Int64, value: Double)] = [
            (count: 2, value: 10.0),
            (count: 2, value: 20.0)
        ]
        let median: Double? = data.medianAssumingAscendingOrder()

        #expect(median == 15.0)
    }

    @Test
    func HandlesLargeCounts() {
        // Test ensures Int64 is respected and does not overflow or miscalculate indices
        let largeCount: Int64 = 1_000_000_000
        let data: [(count: Int64, value: Double)] = [
            (count: largeCount, value: 10.0),
            (count: largeCount, value: 30.0)
        ]
        // Effectively 1 billion 10s and 1 billion 30s.
        // The middle two elements are the last 10.0 and the first 30.0.
        // Average should be 20.0.
        let median: Double? = data.medianAssumingAscendingOrder()

        #expect(median == 20.0)
    }

    @Test
    func SkipsEmptyBucketsCorrectly() {
        // Zeros in the middle should not disrupt the cumulative index count
        // [10.0, (empty), 30.0] -> Total 2. Median (10+30)/2 = 20.0
        let data: [(count: Int64, value: Double)] = [
            (count: 1, value: 10.0),
            (count: 0, value: 20.0), // Should be skipped
            (count: 1, value: 30.0)
        ]
        let median: Double? = data.medianAssumingAscendingOrder()

        #expect(median == 20.0)
    }
}
