extension LocalMarket {
    @frozen public struct State {
        public let id: ID
        public let priceFloor: PriceFloor?
        public let yesterday: Interval
        public let today: Interval

        @inlinable public init(
            id: ID,
            priceFloor: PriceFloor?,
            yesterday: Interval,
            today: Interval
        ) {
            self.id = id
            self.priceFloor = priceFloor
            self.yesterday = yesterday
            self.today = today
        }
    }
}
