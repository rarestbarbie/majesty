import GameIDs

extension StockMarket {
    @frozen public struct Fill {
        public let asset: LEI
        public let buyer: LEI
        public let issued: Quote
        public let market: Quote

        @inlinable init(
            asset: LEI,
            buyer: LEI,
            issued: Quote,
            market: Quote
        ) {
            self.asset = asset
            self.buyer = buyer
            self.issued = issued
            self.market = market
        }
    }
}
