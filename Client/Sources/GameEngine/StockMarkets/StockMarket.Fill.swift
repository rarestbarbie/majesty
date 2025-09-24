extension StockMarket {
    struct Fill {
        let asset: LegalEntity
        let buyer: LegalEntity
        let quantity: Int64
        let cost: Int64
    }
}
