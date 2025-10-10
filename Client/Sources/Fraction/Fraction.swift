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
    /// Multiply the operand by this fraction, rounding away from zero.
    @inlinable public static func >< (self: Self, a: Int64) -> Int64 {
        let (d, r): (Int64, Int64) = self.d.dividingFullWidth(self.n.multipliedFullWidth(by: a))
        return r > 0 ? d + 1 : (r == 0 ? d : d - 1)
    }
    /// Multiply the operand by this fraction, rounding toward zero.
    @inlinable public static func <> (self: Self, a: Int64) -> Int64 {
        let (d, _): (Int64, Int64) = self.d.dividingFullWidth(self.n.multipliedFullWidth(by: a))
        return d
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
