import LiquidityPool

extension WorldMarket {
    @frozen public struct Aggregate {
        public let volume: LiquidityPool.Volume
        public let prices: Candle<Double>

        @inlinable public init(
            volume: LiquidityPool.Volume,
            prices: Candle<Double>,
        ) {
            self.volume = volume
            self.prices = prices
        }
    }
}
