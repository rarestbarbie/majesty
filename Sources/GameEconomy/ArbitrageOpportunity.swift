import GameIDs

@frozen public struct ArbitrageOpportunity {
    public let market: CurrencyID
    public let profit: Int64
    public let volume: Int64

    @inlinable init(
        market: CurrencyID,
        profit: Int64,
        volume: Int64,
    ) {
        self.market = market
        self.profit = profit
        self.volume = volume
    }
}
