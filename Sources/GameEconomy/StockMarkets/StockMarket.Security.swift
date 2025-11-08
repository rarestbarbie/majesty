import GameIDs

extension StockMarket {
    @frozen public struct Security {
        public let id: LEI
        public let stockPrice: StockPrice?
        public let attraction: Double

        @inlinable public init(
            id: LEI,
            stockPrice: StockPrice?,
            attraction: Double
        ) {
            self.id = id
            self.stockPrice = stockPrice
            self.attraction = attraction
        }
    }
}
