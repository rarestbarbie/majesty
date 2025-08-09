@frozen public struct Fraction {
    public let n: Int64
    public let d: Int64

    @inlinable public init(_ n: Int64, _ d: Int64) {
        self.n = n
        self.d = d
    }
}
extension Fraction {
    @inlinable public static func *< (self: Self, a: Int64) -> Int64 {
        let (d, r): (Int64, Int64) = self.d.dividingFullWidth(self.n.multipliedFullWidth(by: a))
        return r > 0 ? d + 1 : (r == 0 ? d : d - 1)
    }
    @inlinable public static func *> (self: Self, a: Int64) -> Int64 {
        let (d, _): (Int64, Int64) = self.d.dividingFullWidth(self.n.multipliedFullWidth(by: a))
        return d
    }
}
extension Fraction {
    @inlinable public static func *> (a: Int64, self: Self) -> Int64 {
        self *> a
    }
    @inlinable public static func *< (a: Int64, self: Self) -> Int64 {
        self *< a
    }
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
