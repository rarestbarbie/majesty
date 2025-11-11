extension LocalMarket {
    @frozen public struct State {
        public let id: ID
        public let yesterday: Interval
        public let today: Interval
        public let limit: (
            min: LocalPriceLevel?,
            max: LocalPriceLevel?
        )

        @inlinable public init(
            id: ID,
            yesterday: Interval,
            today: Interval,
            limit: (min: LocalPriceLevel?, max: LocalPriceLevel?),
        ) {
            self.id = id
            self.yesterday = yesterday
            self.today = today
            self.limit = limit
        }
    }
}
