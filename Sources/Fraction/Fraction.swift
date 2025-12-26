@frozen public struct Fraction {
    public let n: Int64
    public let d: Int64

    @inlinable public init(_ n: Int64, _ d: Int64) {
        self.n = n
        self.d = d
    }
}
extension Fraction: CustomStringConvertible {
    @inlinable public var description: String { "\(self.n)/\(self.d)" }
}
extension Fraction: LosslessStringConvertible {
    @inlinable public init?(_ string: some StringProtocol) {
        guard
        let i: String.Index = string.firstIndex(of: "/"),
        let n: Int64 = .init(string[..<i]),
        let d: Int64 = .init(string[string.index(after: i)...]) else {
            return nil
        }
        self.init(n, d)
    }
}
extension Fraction: ExpressibleByIntegerLiteral {
    @inlinable public init(integerLiteral value: Int64) {
        self.init(value, 1)
    }
}
extension Fraction {
    @inlinable public static func * (a: Self, b: Self) -> Self {
        .init(a.n * b.n, a.d * b.d)
    }
    @inlinable public static func / (a: Self, b: Self) -> Self {
        .init(a.n * b.d, a.d * b.n)
    }

    @inlinable public static func * (a: Self, b: Int64) -> Self {
        .init(a.n * b, a.d)
    }
    @inlinable public static func * (a: Int64, b: Self) -> Self {
        .init(a * b.n, b.d)
    }
}
extension Fraction {
    /// Multiply the operand by this fraction, rounding away from zero.
    @inlinable public static func >< (self: Self, a: Int64) -> Int64 {
        let n: (high: Int64, low: UInt64) = self.n.multipliedFullWidth(by: a)
        if  n.high == 0, Int64.init(bitPattern: n.low) >= 0 {
            let n: Int64 = Int64.init(bitPattern: n.low)
            let (d, r): (Int64, Int64) = n.quotientAndRemainder(dividingBy: self.d)
            return r > 0 ? d + 1 : (r == 0 ? d : d - 1)
        } else {
            let (d, r): (Int64, Int64) = self.d.dividingFullWidth(n)
            return r > 0 ? d + 1 : (r == 0 ? d : d - 1)
        }
    }
    /// Multiply the operand by this fraction, rounding toward zero.
    @inlinable public static func <> (self: Self, a: Int64) -> Int64 {
        let n: (high: Int64, low: UInt64) = self.n.multipliedFullWidth(by: a)
        if  n.high == 0, Int64.init(bitPattern: n.low) >= 0 {
            return Int64.init(bitPattern: n.low) / self.d
        } else {
            let (d, _): (Int64, Int64) = self.d.dividingFullWidth(n)
            return d
        }
    }

    @inlinable public var roundedDown: Int64 {
        let (d, r): (Int64, remainder: Int64) = self.n.quotientAndRemainder(dividingBy: self.d)
        return r < 0 ? d - 1 : d
    }
    @inlinable public var roundedUp: Int64 {
        let (d, r): (Int64, remainder: Int64) = self.n.quotientAndRemainder(dividingBy: self.d)
        return r > 0 ? d + 1 : d
    }
}
extension Fraction {
    @inlinable public static func >< (a: Int64, self: Self) -> Int64 { self >< a }
    @inlinable public static func <> (a: Int64, self: Self) -> Int64 { self <> a }
}
extension Fraction: Equatable {
    @inlinable public static func == (a: Self, b: Self) -> Bool {
        Int128.init(a.n) * Int128.init(b.d) == Int128.init(b.n) * Int128.init(a.d)
    }
}
extension Fraction: Comparable {
    @inlinable public static func < (a: Self, b: Self) -> Bool {
        Int128.init(a.n) * Int128.init(b.d) < Int128.init(b.n) * Int128.init(a.d)
    }
}
