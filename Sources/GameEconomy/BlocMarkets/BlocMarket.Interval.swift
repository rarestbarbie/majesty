import LiquidityPool

extension BlocMarket {
    @frozen public struct Interval {
        public let prices: Candle<Double>
        public let volume: LiquidityPool.Volume
        public let liquidity: Double

        @inlinable public init(
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
