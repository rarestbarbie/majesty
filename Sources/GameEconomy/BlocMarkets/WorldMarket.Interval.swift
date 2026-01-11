import LiquidityPool

extension WorldMarket {
    @frozen public struct Interval {
        public let assets: LiquidityPool.Assets
        public let volume: LiquidityPool.Volume
        public let prices: Candle<Double>

        @inlinable public init(
            assets: LiquidityPool.Assets,
            volume: LiquidityPool.Volume,
            prices: Candle<Double>,
        ) {
            self.assets = assets
            self.volume = volume
            self.prices = prices
        }
    }
}
