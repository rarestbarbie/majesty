import GameEconomy
import Testing

@Suite struct LiquidityPoolTests {
    @Test static func illiquid() {
        var A: LiquidityPool = .init(liq: (1, 2))
        var B: LiquidityPool = .init(liq: (1, 1))
        var C: LiquidityPool = .init(liq: (2, 1))

        var q: Int64 = 1_000_000
        var b: Int64 = 1_000_000

        // It should be impossible to buy the base instrument if it has a liquidity of 1.
        #expect(A.buy(1, with: &q) == 0)
        #expect(B.buy(1, with: &q) == 0)

        // Likewise for the quote instrument.
        #expect(B.sell(&b) == 0)
        #expect(C.sell(&b) == 0)

        // No funds should have moved.
        #expect(A.liq == (1, 2))
        #expect(B.liq == (1, 1))
        #expect(C.liq == (2, 1))
        #expect(q == 1_000_000)
        #expect(b == 1_000_000)
    }

    @Test static func buy() {
        var A: LiquidityPool = .init(liq: (2, 2))
        var B: LiquidityPool = .init(liq: (3, 2))
        var C: LiquidityPool = .init(liq: (4, 1))

        #expect(A.buy(1) == (bought: 1, for: 2))
        #expect(B.buy(2) == (bought: 2, for: 4))
        #expect(C.buy(2) == (bought: 2, for: 1))
    }

    @Test static func sell() {
        var A: LiquidityPool = .init(liq: (1, 4))
        var B: LiquidityPool = .init(liq: (2, 3))
        var C: LiquidityPool = .init(liq: (2, 2))

        #expect(A.sell(1) == (sold: 1, for: 2))
        #expect(B.sell(4) == (sold: 4, for: 2))
        #expect(C.sell(2) == (sold: 2, for: 1))
    }

    @Test static func overbuy() {
        var A: LiquidityPool = .init(liq: (2, 2))
        var B: LiquidityPool = .init(liq: (3, 2))
        var C: LiquidityPool = .init(liq: (4, 1))

        #expect(A.buy(.max) == (bought: 1, for: 2))
        #expect(B.buy(.max) == (bought: 2, for: 4))
        #expect(C.buy(.max) == (bought: 3, for: 3))
    }

    @Test static func oversell() {
        var A: LiquidityPool = .init(liq: (1, 4))
        var B: LiquidityPool = .init(liq: (2, 3))
        var C: LiquidityPool = .init(liq: (2, 2))

        #expect(A.sell(.max) == (sold: 3, for: 3))
        #expect(B.sell(.max) == (sold: 4, for: 2))
        #expect(C.sell(.max) == (sold: 2, for: 1))
    }

    @Test static func swaps() {
        var x: LiquidityPool = .init(liq: (base: 100, quote: 1000))

        // Selling 10 `x` should push down its price in `y`.
        #expect(x.sell(10) == (10, for: 90))
        #expect(x.sell(10) == (10, for: 75))
        #expect(x.vol.base == (i: 20, o: 0))
        #expect(x.vol.quote == (i: 0, o: 165))

        var y: LiquidityPool = .init(liq: (base: 1000, quote: 100))

        // Liquidity pool should be symmetric.
        #expect(y.conjugated.sell(10) == (10, for: 90))
        #expect(y.conjugated.sell(10) == (10, for: 75))
        #expect(y.vol.quote == (i: 20, o: 0))
        #expect(y.vol.base == (i: 0, o: 165))
    }

    @Test static func purchases() {
        do {
            var pool: LiquidityPool = .init(liq: (base: 100, quote: 1000))
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
            var pool: LiquidityPool = .init(liq: (base: 1000, quote: 100))
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
}
