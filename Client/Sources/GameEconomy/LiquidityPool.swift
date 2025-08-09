@frozen public struct LiquidityPool {
    public var liq: (base: Int64, quote: Int64)
    /// Volume.
    ///
    /// Unsigned volume is computed as `$0.i + $0.o`, where `i` represents taker volume and `o`
    /// represents maker volume. Maker volume will always be slightly lower than taker volume,
    /// because market makers keep a small fraction of the value of each trade as a profit.
    ///
    /// Signed volume is only meaningful when the inflow on one side of the market is multiplied
    /// with the outflow on the other side of the market. Thus, it has units of `base * quote`.
    public var vol: (base: (i: Int64, o: Int64), quote: (i: Int64, o: Int64))

    @inlinable public init(
        liq: (base: Int64, quote: Int64) = (2, 2),
        vol: (base: (i: Int64, o: Int64), quote: (i: Int64, o: Int64)) = ((0, 0), (0, 0))) {
        self.liq = liq
        self.vol = vol
    }
}
extension LiquidityPool {
    @inlinable public var conjugated: Self {
        get {
            .init(liq: (self.liq.1, self.liq.0), vol: (self.vol.1, self.vol.0) )
        }
        set(value) {
            self.liq = (value.liq.1, value.liq.0)
            self.vol = (value.vol.1, value.vol.0)
        }
    }

    @inlinable public var ratio: Fraction { self.liq.quote %/ self.liq.base }
}
extension LiquidityPool {
    /// The ask price is how much of the quote instrument you would have to pay for one unit of
    /// the base instrument.
    @inlinable public var ask: Int64? {
        if self.liq.base < 2 {
            // If the base liquidity is less than 2, the ask price is undefined.
            return nil
        }
        let bl: Int128 = .init(self.liq.base)
        let ql: Int128 = .init(self.liq.quote)
        let (b, r): (Int128, Int128) = ql.quotientAndRemainder(dividingBy: bl - 1)
        return (r > 0 ? Int64.init(b) + 1 : Int64.init(b))
    }
    /// The bid price is how much of the quote instrument you would receive for one unit of the
    /// base instrument.
    @inlinable public var bid: Int64 {
        let bl: Int128 = .init(self.liq.base)
        let ql: Int128 = .init(self.liq.quote)
        let q: Int128 = ql / (bl + 1)
        return Int64.init(q)
    }
}
extension LiquidityPool {
    func quote(_ base: Int64) -> (cost: Int64, amount: Int64) {
        let bl: Int128 = .init(self.liq.base)
        let ql: Int128 = .init(self.liq.quote)

        let base: Int128 = .init(base)
        /// This is the amount that we could receive if we spent all of `base`.
        let q: Int128 = (ql * base) / (bl + base)
        let (b, r): (Int128, Int128) = (bl * q).quotientAndRemainder(dividingBy: ql - q)
        return (r > 0 ? Int64.init(b) + 1 : Int64.init(b), Int64.init(q))
    }

    func quote(_ base: Int64, limit: Int64) -> (cost: Int64, amount: Int64) {
        let bl: Int128 = .init(self.liq.base)
        let ql: Int128 = .init(self.liq.quote)

        let base: Int128 = .init(base)
        let q: Int128 = min((ql * base) / (bl + base), Int128.init(limit))
        let (b, r): (Int128, Int128) = (bl * q).quotientAndRemainder(dividingBy: ql - q)
        return (r > 0 ? Int64.init(b) + 1 : Int64.init(b), Int64.init(q))
    }

    private mutating func swap(base: Int64, for quote: Int64) -> Int64 {
        self.liq.base += base
        self.vol.base.i += base
        self.liq.quote -= quote
        self.vol.quote.o += quote
        return quote
    }
}
extension LiquidityPool {
    public mutating func stake(_ base: Int64) -> Fraction {
        self.liq.base += base
        return base %/ self.liq.base
    }
}
extension LiquidityPool {
    /// Sell up to `base` amount of the base instrument, returning the amount of the quote
    /// instrument received.
    public mutating func sell(_ base: inout Int64) -> Int64 {
        let (b, q): (cost: Int64, Int64) = self.quote(base)
        defer { base -= b }
        return self.swap(base: b, for: q)
    }

    /// Swap `base` amount of the base instrument for up to `limit` amount of the quote
    /// instrument, returning the amount of the quote instrument received.
    public mutating func swap(_ base: inout Int64, limit: Int64) -> Int64 {
        let (b, q): (cost: Int64, Int64) = self.quote(base, limit: limit)
        defer { base -= b }
        return self.swap(base: b, for: q)
    }

    public mutating func buy(_ limit: Int64, with quote: inout Int64) -> Int64 {
        let (q, b): (cost: Int64, Int64) = self.conjugated.quote(quote, limit: limit)
        defer { quote -= q }
        return self.conjugated.swap(base: q, for: b)
    }
}
