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
        public var base: (i: Int64, o: Int64)
        public var quote: (i: Int64, o: Int64)

        @inlinable public init(
            base: (i: Int64, o: Int64) = (0, 0),
            quote: (i: Int64, o: Int64) = (0, 0)
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

    @inlinable public var unsigned: Int64 {
        self.base.i + self.base.o
    }

    @inlinable public mutating func reset() {
        self.base = (0, 0)
        self.quote = (0, 0)
    }
}
extension LiquidityPool.Volume {
    mutating func swap(base: Int64, for quote: Int64) {
        self.base.i += base
        self.quote.o += quote
    }
}
