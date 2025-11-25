import GameIDs

extension StockMarket {
    @frozen @usableFromInline struct RandomPurchase {
        @usableFromInline let buyer: LEI
        @usableFromInline let value: Int64

        @inlinable init(buyer: LEI, value: Int64) {
            self.buyer = buyer
            self.value = value
        }
    }
}
