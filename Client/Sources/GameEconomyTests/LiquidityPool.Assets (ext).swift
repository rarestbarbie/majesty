import GameEconomy

extension LiquidityPool.Assets {
    static func == (self: Self, liquidity: (base: Int64, quote: Int64)) -> Bool {
        (self.base, self.quote) == liquidity
    }
}
