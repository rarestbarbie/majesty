import GameIDs

extension StockMarket {
    @frozen public struct Fill {
        public let asset: LEI
        public let buyer: LEI
        public let issued: StockPrice.Quote
        public let market: StockPrice.Quote

        @inlinable init(
            asset: LEI,
            buyer: LEI,
            issued: StockPrice.Quote,
            market: StockPrice.Quote
        ) {
            self.asset = asset
            self.buyer = buyer
            self.issued = issued
            self.market = market
        }
    }
}
