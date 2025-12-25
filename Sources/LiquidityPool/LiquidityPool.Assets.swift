import Fraction

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
    @inlinable public func quote(_ base: Int64) -> (cost: Int64, amount: Int64) {
        let bl: Int128 = .init(self.base)
        let ql: Int128 = .init(self.quote)

        let base: Int128 = .init(base)
        /// This is the amount that we could receive if we spent all of `base`.
        let q: Int128 = (ql * base) / (bl + base)
        let (b, r): (Int128, Int128) = (bl * q).quotientAndRemainder(dividingBy: ql - q)
        return (r > 0 ? Int64.init(b) + 1 : Int64.init(b), Int64.init(q))
    }

    @inlinable public func quote(_ base: Int64, limit: Int64) -> (cost: Int64, amount: Int64) {
        // callers check for zeros quite frequently, so we don’t bother including a
        // short-circuit for zeros here

        // not sure if the optimization below is effective in practice

        // If inputs are < 2^32, their product fits in 2^64 (Int64), avoiding Int128 completely.
        // 4,294,967,295 is Int32.max.
        // if  Int32.max > base,
        //     Int32.max > self.base,
        //     Int32.max > self.quote {
        //     return self.quote64(base, limit: limit)
        // }

        let bl: Int128 = .init(self.base)
        let ql: Int128 = .init(self.quote)

        let limit: Int128 = .init(limit)
        let base: Int128 = .init(base)

        let n: Int128 = ql * base
        let d: Int128 = bl + base

        // 128-bit integer division is slow, check limit using multiplication to avoid it
        let q: Int128 = n >= limit * d ? limit : n / d
        let (b, r): (Int128, Int128) = (bl * q).quotientAndRemainder(dividingBy: ql - q)
        return (r > 0 ? Int64.init(b) + 1 : Int64.init(b), Int64.init(q))
    }

    @inlinable func quote64(_ base: Int64, limit: Int64) -> (cost: Int64, amount: Int64) {
        let bl: Int64 = self.base
        let ql: Int64 = self.quote

        let n: Int64 = ql * base
        let d: Int64 = bl + base
        let q: Int64 = n >= limit * d ? limit : n / d

        let (b, r): (Int64, Int64) = (bl * q).quotientAndRemainder(dividingBy: ql - q)
        return (r > 0 ? b + 1 : b, q)
    }

    mutating func swap(base: Int64, for quote: Int64) {
        self.base += base
        self.quote -= quote
    }

    @discardableResult
    @inlinable public mutating func drain(_ fraction: Fraction) -> Self {
        let drained: Self = .init(
            base: self.base <> fraction,
            quote: self.quote <> fraction
        )

        self.base -= drained.base
        self.quote -= drained.quote

        return drained
    }
}
