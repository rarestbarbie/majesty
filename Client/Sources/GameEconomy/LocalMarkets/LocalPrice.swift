import Fraction
import D

@frozen public struct LocalPrice: Equatable, Hashable {
    public var per100: Int64

    @inlinable public init(per100: Int64) {
        self.per100 = per100
    }
}
extension LocalPrice {
    @inlinable public var exact: Fraction { self.per100 %/ 100 }
    @inlinable public var value: Decimal { .init(units: self.per100, power: -2) }
}
extension LocalPrice: Comparable {
    @inlinable public static func < (a: Self, b: Self) -> Bool { a.per100 < b.per100 }
}
