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
        /// Formula: q = (ql * base) / (bl + base)
        /// where `q` is the amount that we could receive if we spent all of `base`
        let n: (full: Int128, high: Int64, low: UInt64)
        let d: (full: Int128, overflow: Bool, low: Int64)

        (n.high, n.low) = self.quote.multipliedFullWidth(by: base)
        (d.low, d.overflow) = self.base.addingReportingOverflow(base)

        let q: Int64

        if !d.overflow, n.high == 0 {
            // if components fit in 64 bits, use native division
            q = Int64.init(n.low / UInt64.init(d.low))
        } else {
            // fallback to Int128
            n.full = Int128.init(n.low) | Int128.init(n.high) << 64
            d.full = Int128.init(UInt64.init(bitPattern: d.low))
            q = Int64.init(n.full / d.full)
        }

        return self.quote(cost: q)
    }

    @inlinable public func quote(_ base: Int64, limit: Int64) -> (cost: Int64, amount: Int64) {
        // callers check for zeros quite frequently, so we don’t bother including a
        // short-circuit for zeros here
        let n: (full: Int128, high: Int64, low: UInt64)
        let d: (full: Int128?, overflow: Bool, low: Int64)

        (n.high, n.low) = self.quote.multipliedFullWidth(by: base)
        (d.low, d.overflow) = self.base.addingReportingOverflow(base)

        // 128-bit integer division is slow, check limit using multiplication to avoid it
        let t: (high: Int64, low: UInt64)
        if  d.overflow {
            // this is rare, since we expect `base` to be much smaller than `self.base`
            // we can just extract the `UInt64` bit pattern, since the result of adding two
            // non-negative `Int64`s will never overflow more than one bit
            let denominator: Int128 = .init(UInt64.init(bitPattern: d.low))
            let threshold: Int128 = denominator * Int128.init(limit)

            t.high = Int64.init(truncatingIfNeeded: threshold >> 64)
            t.low = UInt64.init(truncatingIfNeeded: threshold)
            d.full = denominator
        } else {
            t = limit.multipliedFullWidth(by: d.low)
            d.full = nil
        }

        let q: Int64

        if (n.high, n.low) >= (t.high, t.low) {
            q = limit
        } else {
            if !d.overflow, n.high == 0 {
                // if components fit in 64 bits, use native division
                q = Int64.init(n.low / UInt64.init(d.low))
            } else {
                // fallback to Int128
                n.full = Int128.init(n.low) | Int128.init(n.high) << 64
                q = Int64.init(n.full / (d.full ?? Int128.init(d.low)))
            }
        }

        return self.quote(cost: q)
    }

    @inlinable func quote(cost q: Int64) -> (cost: Int64, amount: Int64) {
        // optimization for `(b, r) = (bl * q) / (ql - q)`
        let p: Int64 = self.quote - q
        let m: (high: Int64, low: UInt64) = self.base.multipliedFullWidth(by: q)
        if  m.high == 0 {
            // if the high bits are 0, the result fits entirely in a 64-bit register,
            // and this could be much faster
            let m: UInt64 = m.low
            let (b, r): (UInt64, UInt64) = m.quotientAndRemainder(dividingBy: UInt64.init(p))
            return (r > 0 ? Int64.init(b) + 1 : Int64.init(b), q)
        } else {
            let m: Int128 = Int128.init(m.low) | Int128.init(m.high) << 64
            let (b, r): (Int128, Int128) = m.quotientAndRemainder(dividingBy: Int128.init(p))
            return (r > 0 ? Int64.init(b) + 1 : Int64.init(b), q)
        }
    }

    mutating func swap(base: Int64, for quote: Int64) {
        self.base += base
        self.quote -= quote
    }
}
