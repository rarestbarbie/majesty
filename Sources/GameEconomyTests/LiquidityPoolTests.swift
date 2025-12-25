import LiquidityPool
import Testing

@Suite struct LiquidityPoolTests {
    @Test static func Illiquid() {
        var A: LiquidityPool = .init(liquidity: (1, 2))
        var B: LiquidityPool = .init(liquidity: (1, 1))
        var C: LiquidityPool = .init(liquidity: (2, 1))

        var q: Int64 = 1_000_000
        var b: Int64 = 1_000_000

        // It should be impossible to buy the base instrument if it has a liquidity of 1.
        #expect(A.buy(1, with: &q) == 0)
        #expect(B.buy(1, with: &q) == 0)

        // Likewise for the quote instrument.
        #expect(B.sell(&b) == 0)
        #expect(C.sell(&b) == 0)

        // No funds should have moved.
        #expect(A.assets == (1, 2))
        #expect(B.assets == (1, 1))
        #expect(C.assets == (2, 1))
        #expect(q == 1_000_000)
        #expect(b == 1_000_000)
    }

    @Test static func Buy() {
        var A: LiquidityPool = .init(liquidity: (2, 2))
        var B: LiquidityPool = .init(liquidity: (3, 2))
        var C: LiquidityPool = .init(liquidity: (4, 1))

        #expect(A.buy(1) == (bought: 1, for: 2))
        #expect(B.buy(2) == (bought: 2, for: 4))
        #expect(C.buy(2) == (bought: 2, for: 1))
    }

    @Test static func Sell() {
        var A: LiquidityPool = .init(liquidity: (1, 4))
        var B: LiquidityPool = .init(liquidity: (2, 3))
        var C: LiquidityPool = .init(liquidity: (2, 2))

        #expect(A.sell(1) == (sold: 1, for: 2))
        #expect(B.sell(4) == (sold: 4, for: 2))
        #expect(C.sell(2) == (sold: 2, for: 1))
    }

    @Test static func Overbuy() {
        var A: LiquidityPool = .init(liquidity: (2, 2))
        var B: LiquidityPool = .init(liquidity: (3, 2))
        var C: LiquidityPool = .init(liquidity: (4, 1))

        #expect(A.buy(.max) == (bought: 1, for: 2))
        #expect(B.buy(.max) == (bought: 2, for: 4))
        #expect(C.buy(.max) == (bought: 3, for: 3))
    }

    @Test static func Oversell() {
        var A: LiquidityPool = .init(liquidity: (1, 4))
        var B: LiquidityPool = .init(liquidity: (2, 3))
        var C: LiquidityPool = .init(liquidity: (2, 2))

        #expect(A.sell(.max) == (sold: 3, for: 3))
        #expect(B.sell(.max) == (sold: 4, for: 2))
        #expect(C.sell(.max) == (sold: 2, for: 1))
    }

    @Test static func Swaps() {
        var x: LiquidityPool = .init(liquidity: (base: 100, quote: 1000))

        // Selling 10 `x` should push down its price in `y`.
        #expect(x.sell(10) == (10, for: 90))
        #expect(x.sell(10) == (10, for: 75))
        #expect(x.volume.base.total == 20)
        #expect(x.volume.quote.total == 165)

        var y: LiquidityPool = .init(liquidity: (base: 1000, quote: 100))

        // Liquidity pool should be symmetric.
        #expect(y.conjugated.sell(10) == (10, for: 90))
        #expect(y.conjugated.sell(10) == (10, for: 75))
        #expect(y.volume.quote.total == 20)
        #expect(y.volume.base.total == 165)
    }

    @Test static func Purchases() {
        do {
            var pool: LiquidityPool = .init(liquidity: (base: 100, quote: 1000))
            var x: Int64 = 1_000_000

            #expect(pool.swap(&x, limit: 0) == 0)
            #expect(x == 1_000_000)

            #expect(pool.swap(&x, limit: 90) == 90)
            #expect(x == 1_000_000 - 10)

            #expect(pool.swap(&x, limit: 75) == 75)
            #expect(x == 1_000_000 - 20)

            // It should be impossible to buy the last unit of `y` in the pool.
            #expect(pool.swap(&x, limit: 1_000_000) == 1000 - 90 - 75 - 1)
            #expect(x == 899_900)
        }
        do {
            var pool: LiquidityPool = .init(liquidity: (base: 1000, quote: 100))
            var y: Int64 = 1_000_000

            #expect(pool.conjugated.swap(&y, limit: 0) == 0)
            #expect(y == 1_000_000)

            #expect(pool.conjugated.swap(&y, limit: 90) == 90)
            #expect(y == 1_000_000 - 10)

            #expect(pool.conjugated.swap(&y, limit: 75) == 75)
            #expect(y == 1_000_000 - 20)

            // It should be impossible to buy the last unit of `x` in the pool.
            #expect(pool.conjugated.swap(&y, limit: 1_000_000) == 1000 - 90 - 75 - 1)
            #expect(y == 899_900)
        }
    }

    /// Tests Path 1 (Numerator Overflow) & Path 3 (Cost Calculation Overflow)
    /// Scenario: Reserves are 10 Trillion. User swaps 10 Trillion.
    /// Math:
    ///   Numerator = 10T * 10T = 100e24 (Overflows 64-bit)
    ///   Denominator = 10T + 10T = 20T
    ///   q = 100e24 / 20T = 5T
    /// Cost Check:
    ///   CostNum = 10T * 5T = 50e24 (Overflows 64-bit)
    ///   CostDen = 10T - 5T = 5T
    ///   Cost = 50e24 / 5T = 10T
    @Test static func WhaleTradeOverflow() {
        // 10 Trillion (1e13)
        let x: Int64 = 10_000_000_000_000
        let pool: LiquidityPool = .init(liquidity: (base: x, quote: x))

        // This call triggers `n.high != 0` in `quote(_ base)`
        // AND `m.high != 0` in `quote(cost:)`
        let result: (cost: Int64, amount: Int64) = pool.assets.quote(x)

        #expect(result.amount == 5_000_000_000_000)
        #expect(result.cost == 10_000_000_000_000)
    }

    /// Tests Path 2 (Denominator Overflow)
    /// Scenario: Base reserve is near Int64.max.
    /// Math:
    ///   Base = Int64.max - 100
    ///   Input = 200
    ///   Denominator = (Max - 100) + 200 = Max + 100 (Overflows 64-bit signed)
    ///   Numerator = 1000 * 200 = 200,000
    ///   q = 200,000 / (Max + 100) = 0
    @Test static func DenominatorOverflow() {
        let x: Int64 = Int64.max - 100
        let pool: LiquidityPool = .init(liquidity: (base: x, quote: 1000))

        // This triggers `d.overflow == true` but `n.high == 0`
        let result: (cost: Int64, amount: Int64) = pool.assets.quote(200)

        #expect(result.amount == 0)
        #expect(result.cost == 0)
    }

    /// Tests Path 4 (Limit Threshold Overflow)
    /// Scenario: Denominator overflows, forcing the Limit check to use 128-bit math.
    @Test static func limitCheckOverflow() {
        let x: Int64 = Int64.max - 100
        let pool: LiquidityPool = .init(liquidity: (base: x, quote: 1000))

        // Swap 200. Denominator overflows.
        // We set a limit of 1.
        // Threshold Check:
        //   Denominator (approx 9e18) * Limit (1) = 9e18
        //   Numerator (200,000)
        //   Numerator < Threshold, so Limit is NOT hit.
        //   Proceeds to calculate q = 0.
        let result: (cost: Int64, amount: Int64) = pool.assets.quote(200, limit: 1)
        #expect(result.amount == 0)
    }

    /// Tests Mixed Path: Numerator Fits, Denominator Fits (Fast Path)
    /// Ensures the optimization didn't break standard large-but-safe numbers.
    @Test static func largeNumbersFastPath() {
        // 1 Billion. Product is 1e18 (Fits in 64-bit, barely).
        // 1,000,000,000 * 1,000,000,000 = 1,000,000,000,000,000,000
        // UInt64.max is ~18,446,000,000,000,000,000.
        let x: Int64 = 1_000_000_000
        let pool: LiquidityPool = .init(liquidity: (base: x, quote: x))

        let result: (cost: Int64, amount: Int64) = pool.assets.quote(x)

        // q = 1e18 / 2e9 = 500,000,000
        #expect(result.amount == 500_000_000)
    }
}
