extension LiquidityPool {
    @frozen public struct Assets {
        public var base: Int64
        public var quote: Int64

        @inlinable public init(base: Int64, quote: Int64) {
            self.base = base
            self.quote = quote
        }
    }
}
extension LiquidityPool.Assets {
    @inlinable public var ratio: Fraction { self.quote %/ self.base }

    @inlinable var conjugated: Self {
        .init(base: self.quote, quote: self.base)
    }

    @inlinable var ask: Int64? {
        if self.base < 2 {
            // If the base liquidity is less than 2, the ask price is undefined.
            return nil
        }
        let bl: Int128 = .init(self.base)
        let ql: Int128 = .init(self.quote)
        let (b, r): (Int128, Int128) = ql.quotientAndRemainder(dividingBy: bl - 1)
        return (r > 0 ? Int64.init(b) + 1 : Int64.init(b))
    }

    @inlinable var bid: Int64 {
        let bl: Int128 = .init(self.base)
        let ql: Int128 = .init(self.quote)
        let q: Int128 = ql / (bl + 1)
        return Int64.init(q)
    }
}
extension LiquidityPool.Assets {
    func quote(_ base: Int64) -> (cost: Int64, amount: Int64) {
        let bl: Int128 = .init(self.base)
        let ql: Int128 = .init(self.quote)

        let base: Int128 = .init(base)
        /// This is the amount that we could receive if we spent all of `base`.
        let q: Int128 = (ql * base) / (bl + base)
        let (b, r): (Int128, Int128) = (bl * q).quotientAndRemainder(dividingBy: ql - q)
        return (r > 0 ? Int64.init(b) + 1 : Int64.init(b), Int64.init(q))
    }

    func quote(_ base: Int64, limit: Int64) -> (cost: Int64, amount: Int64) {
        let bl: Int128 = .init(self.base)
        let ql: Int128 = .init(self.quote)

        let base: Int128 = .init(base)
        let q: Int128 = min((ql * base) / (bl + base), Int128.init(limit))
        let (b, r): (Int128, Int128) = (bl * q).quotientAndRemainder(dividingBy: ql - q)
        return (r > 0 ? Int64.init(b) + 1 : Int64.init(b), Int64.init(q))
    }

    mutating func swap(base: Int64, for quote: Int64) {
        self.base += base
        self.quote -= quote
    }

    @discardableResult
    @inlinable mutating func drain(_ fraction: Fraction) -> Self {
        let drained: Self = .init(
            base: self.base <> fraction,
            quote: self.quote <> fraction
        )

        self.base -= drained.base
        self.quote -= drained.quote

        return drained
    }
}
