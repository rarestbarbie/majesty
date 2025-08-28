extension Market {
    @frozen public struct Interval {
        public let prices: Candle<Double>
        public let volume: Int64

        @inlinable init(prices: Candle<Double>, volume: Int64) {
            self.prices = prices
            self.volume = volume
        }
    }
}
