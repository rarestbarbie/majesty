import Fraction

@frozen public struct LiquidityPool {
    public var assets: Assets
    public var volume: Volume
    public var fee: Double

    @inlinable public init() {
        self.assets = .init(base: 2, quote: 2)
        self.volume = .init()
        self.fee = 0
    }
    @inlinable public init(
        assets: Assets,
        volume: Volume,
        fee: Double,
    ) {
        self.assets = assets
        self.volume = volume
        self.fee = fee
    }
}
extension LiquidityPool {
    @inlinable public var conjugated: Self {
        get {
            .init(assets: self.assets.conjugated, volume: self.volume.conjugated, fee: self.fee)
        }
        set(value) {
            self.assets = value.assets.conjugated
            self.volume = value.volume.conjugated
            self.fee = value.fee
        }
    }
}
extension LiquidityPool {
    /// Infinitessimal price of the base instrument in units of the quote instrument.
    @inlinable public var price: Double { .init(self.assets.ratio) }
    /// The ask price is how much of the quote instrument you would have to pay for one unit of
    /// the base instrument.
    @inlinable public var ask: Int64? { self.assets.ask }
    /// The bid price is how much of the quote instrument you would receive for one unit of the
    /// base instrument.
    @inlinable public var bid: Int64 { self.assets.bid }
}
extension LiquidityPool {
    private mutating func swap(base: Int64, for quote: Int64) -> Int64 {
        self.assets.swap(base: base, for: quote)
        self.volume.swap(base: base, for: quote)
        /// fee rounds down
        let fee: Int64 = Int64.init(Double.init(quote) * self.fee)
        self.assets.quote += fee
        return quote - fee
    }
}
extension LiquidityPool {
    /// Sell up to `base` amount of the base instrument, returning the amount of the quote
    /// instrument received.
    public mutating func sell(_ base: inout Int64) -> Int64 {
        let (b, q): (cost: Int64, Int64) = self.assets.quote(base)
        defer { base -= b }
        return self.swap(base: b, for: q)
    }

    /// Swap `base` amount of the base instrument for up to `limit` amount of the quote
    /// instrument, returning the amount of the quote instrument received.
    public mutating func swap(_ base: inout Int64, limit: Int64) -> Int64 {
        let (b, q): (cost: Int64, Int64) = self.assets.quote(base, limit: limit)
        defer { base -= b }
        return self.swap(base: b, for: q)
    }

    public mutating func buy(_ limit: Int64, with quote: inout Int64) -> Int64 {
        let (q, b): (cost: Int64, Int64) = self.assets.conjugated.quote(quote, limit: limit)
        defer { quote -= q }
        return self.conjugated.swap(base: q, for: b)
    }
}
