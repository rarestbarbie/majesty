extension Market {
    @frozen public struct Interval {
        public let prices: Candle<Double>
        public let volume: LiquidityPool.Volume

        @inlinable init(prices: Candle<Double>, volume: LiquidityPool.Volume) {
            self.prices = prices
            self.volume = volume
        }
    }
}
