extension LiquidityPool {
    /// Volume.
    ///
    /// Unsigned volume is computed as `$0.i + $0.o`, where `i` represents taker volume and `o`
    /// represents maker volume. Maker volume will always be slightly lower than taker volume,
    /// because market makers keep a small fraction of the value of each trade as a profit.
    ///
    /// Signed volume is only meaningful when the inflow on one side of the market is multiplied
    /// with the outflow on the other side of the market. Thus, it has units of `base * quote`.
    @frozen public struct Volume {
        public var base: Side
        public var quote: Side

        @inlinable public init() {
            self.base = .init()
            self.quote = .init()
        }

        @inlinable public init(
            base: Side,
            quote: Side
        ) {
            self.base = base
            self.quote = quote
        }
    }
}
extension LiquidityPool.Volume {
    @inlinable var conjugated: Self {
        .init(base: self.quote, quote: self.base)
    }

    @inlinable public mutating func reset() {
        self.base.reset()
        self.quote.reset()
    }
}
extension LiquidityPool.Volume {
    mutating func swap(base: Int64, for quote: Int64) {
        self.base.i += base
        self.quote.o += quote
    }
}
