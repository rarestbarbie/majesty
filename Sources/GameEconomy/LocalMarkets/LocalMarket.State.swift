extension LocalMarket {
    @frozen public struct State {
        public let id: ID
        // We don’t currently surface this in the UI, but perhaps we should?
        public let stabilizationFundFees: Int64
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
            stabilizationFundFees: Int64,
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
            self.stabilizationFundFees = stabilizationFundFees
            self.stabilizationFund = stabilizationFund
            self.stockpile = stockpile
            self.yesterday = yesterday
            self.today = today
            self.limit = limit
            self.storage = storage
        }
    }
}
