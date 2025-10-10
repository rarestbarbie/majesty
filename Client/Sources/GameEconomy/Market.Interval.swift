import LiquidityPool

extension Market {
    @frozen public struct Interval {
        public let prices: Candle<Double>
        public let volume: LiquidityPool.Volume
        public let liquidity: Double

        @inlinable init(
            prices: Candle<Double>,
            volume: LiquidityPool.Volume,
            liquidity: Double
        ) {
            self.prices = prices
            self.volume = volume
            self.liquidity = liquidity
        }
    }
}
