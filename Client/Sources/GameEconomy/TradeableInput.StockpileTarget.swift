extension TradeableInput {
    @frozen public struct StockpileTarget {
        public let lower: Int64
        public let today: Int64
        public let upper: Int64

        @inlinable public init(lower: Int64, today: Int64, upper: Int64) {
            self.lower = lower
            self.today = today
            self.upper = upper
        }
    }
}
