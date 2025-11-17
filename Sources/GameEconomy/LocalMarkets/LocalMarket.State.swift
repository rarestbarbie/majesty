extension LocalMarket {
    @frozen public struct State {
        public let id: ID
        public let stabilizationFund: Reservoir
        public let stockpile: Reservoir
        public let yesterday: Interval
        public let today: Interval
        public let limit: (
            min: LocalPriceLevel?,
            max: LocalPriceLevel?
        )
        public let storage: Bool

        @inlinable public init(
            id: ID,
            stabilizationFund: Reservoir,
            stockpile: Reservoir,
            yesterday: Interval,
            today: Interval,
            limit: (
                min: LocalPriceLevel?,
                max: LocalPriceLevel?
            ),
            storage: Bool
        ) {
            self.id = id
            self.stabilizationFund = stabilizationFund
            self.stockpile = stockpile
            self.yesterday = yesterday
            self.today = today
            self.limit = limit
            self.storage = storage
        }
    }
}
