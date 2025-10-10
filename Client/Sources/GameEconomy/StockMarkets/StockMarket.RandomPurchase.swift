import GameIDs

extension StockMarket {
    @frozen @usableFromInline struct RandomPurchase {
        let buyer: LEI
        let value: Int64
    }
}
