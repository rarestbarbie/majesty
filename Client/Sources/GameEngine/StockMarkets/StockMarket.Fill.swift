import GameIDs

extension StockMarket {
    struct Fill {
        let asset: LEI
        let buyer: LEI
        let issued: StockPrice.Quote
        let market: StockPrice.Quote
    }
}
