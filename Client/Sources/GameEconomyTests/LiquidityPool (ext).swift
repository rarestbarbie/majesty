import GameEconomy

extension LiquidityPool {
    init(liquidity: (base: Int64, quote: Int64)) {
        self.init(
            assets: .init(base: liquidity.base, quote: liquidity.quote),
            volume: .init(),
            fee: 0 %/ 1
        )
    }

    mutating func buy(_ base: Int64) -> (bought: Int64, for: Int64) {
        var q: Int64 = .max
        let b: Int64 = self.buy(base, with: &q)
        return (bought: b, for: Int64.max - q)
    }
    mutating func sell(_ base: Int64) -> (sold: Int64, for: Int64) {
        var b: Int64 = base
        let q: Int64 = self.sell(&b)
        return (sold: base - b, for: q)
    }
}
