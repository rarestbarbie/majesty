import Fraction
import Testing

@Suite struct DistributionTests {
    @Test func NoShares() {
        let shares: [Int64] = []
        #expect(shares.distribute(100) == nil)
    }

    @Test func ZeroFunds() {
        let shares: [Int64] = [10, 20, 30]
        #expect(shares.distribute(0) == [0, 0, 0])
    }

    @Test func ZeroShares() {
        let shares: [Int64] = [0, 0, 0]
        #expect(shares.distribute(100) == nil)
    }

    @Test func EvenDistribution() throws {
        let shares: [Int64] = [100, 100, 100, 100]
        let funds: Int64 = 100

        let distribution: [Int64] = try #require(shares.distribute(funds))

        #expect(distribution == [25, 25, 25, 25])
        #expect(distribution.reduce(0, +) == funds)
    }

    @Test func ProportionalDistribution() throws {
        let shares: [Int64] = [10, 30, 60]
        let funds: Int64 = 100

        let distribution: [Int64] = try #require(shares.distribute(funds))

        #expect(distribution == [10, 30, 60])
        #expect(distribution.reduce(0, +) == funds)
    }

    @Test func IntrinsicDistribution() throws {
        let shares: [Int64] = [10, 30, 60]
        let distribution: [Int64] = try #require(shares.distribute(share: \.self) { $0 })

        #expect(distribution == [10, 30, 60])
    }

    @Test func IntrinsicDistributionAvoidsOverfilling() throws {
        let shares: [Int64] = [0, 1, 2]
        let distribution: [Int64] = try #require(shares.distribute(share: \.self) { $0 - 1 })

        #expect(distribution == [0, 1, 1])
    }

    @Test func RoundingFavorsEarlierShareholders() throws {
        let shares: [Int64] = [1, 1, 1]
        let funds: Int64 = 10

        let distribution: [Int64] = try #require(shares.distribute(funds))

        // Each should get 3.33... funds, but we expect earlier shareholders
        // to receive the extra funds
        #expect(distribution == [4, 3, 3])
        #expect(distribution.reduce(0, +) == funds)
    }

    @Test func LargeRoundingCase() throws {
        let shares: [Int64] = [1000, 3000, 6000]
        let funds: Int64 = 9999

        let distribution: [Int64] = try #require(shares.distribute(funds))

        // Expected proportions: 999.9, 2999.7, 5999.4
        // But integers must sum to exactly 9999
        #expect(distribution == [1000, 3000, 5999])
        #expect(distribution.reduce(0, +) == funds)
    }

    @Test func SingleShareholder() throws {
        let shares: [Int64] = [50]
        let funds: Int64 = 1000

        let distribution: [Int64] = try #require(shares.distribute(funds))

        #expect(distribution == [1000])
    }

    @Test func LargeNumbers() throws {
        let shares: [Int64] = [100_000_000, 200_000_000, 300_000_000]
        let funds: Int64 = Int64.max / 2

        let distribution: [Int64] = try #require(shares.distribute(funds))

        // Verify sum equals original funds
        #expect(distribution.reduce(0, +) == funds)

        // Verify proportions are roughly maintained
        let totalShares: Int64 = shares.reduce(0, +)
        for (i, share): (Int, Int64) in shares.enumerated() {
            let expectedProportion: Double = Double.init(share) / Double.init(totalShares)
            let actualProportion: Double = Double.init(distribution[i]) / Double.init(funds)
            #expect(abs(expectedProportion - actualProportion) < 0.0001)
        }
    }

    @Test func LargeNumbersWithOverflow() throws {
        // Use Int.max for funds and a simple share distribution
        let funds: Int64 = Int64.max
        let shares: [Int64] = [2, 1, 1] // 2:1:1 ratio (4 total shares)

        let distribution: [Int64] = try #require(shares.distribute(funds))

        // Integer division of (Int64.max * 2 / 4) = 4,611,686,018,427,387,903
        // Integer division of (Int64.max * 1 / 4) = 2,305,843,009,213,693,951
        // Remaining 2 units should go to the first two shareholders
        let expected: [Int64] = [
            4_611_686_018_427_387_904, // 2/4 of funds + 1 remainder
            2_305_843_009_213_693_952, // 1/4 of funds + 1 remainder
            2_305_843_009_213_693_951  // 1/4 of funds
        ]

        #expect(distribution == expected)
        #expect(distribution.reduce(0, +) == funds)
    }

    @Test func SomeZeroShares() throws {
        let shares: [Int64] = [10, 0, 20, 0]
        let funds: Int64 = 30

        let distribution: [Int64] = try #require(shares.distribute(funds))

        #expect(distribution == [10, 0, 20, 0])
        #expect(distribution.reduce(0, +) == funds)
    }
}
