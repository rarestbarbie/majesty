import Fraction
import D

extension Decimal {
    @inlinable public static func >< (self: Self, a: Int64) -> Int64 {
        switch self.fraction {
        case (let n, denominator: let d?): (n %/ d) >< a
        case (let n, denominator: nil): n * a
        }
    }
    @inlinable public static func <> (self: Self, a: Int64) -> Int64 {
        switch self.fraction {
        case (let n, denominator: let d?): (n %/ d) <> a
        case (let n, denominator: nil): n * a
        }
    }
}
extension Decimal {
    @inlinable public static func >< (a: Int64, self: Self) -> Int64 { self >< a }
    @inlinable public static func <> (a: Int64, self: Self) -> Int64 { self <> a }
}
