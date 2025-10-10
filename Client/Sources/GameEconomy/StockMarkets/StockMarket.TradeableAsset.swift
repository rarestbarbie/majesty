extension StockMarket {
    @frozen @usableFromInline struct TradeableAsset {
        let security: Security
        var issuable: Int64
    }
}
