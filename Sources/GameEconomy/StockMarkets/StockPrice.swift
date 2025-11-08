import Fraction

/// A stock price is a fraction whose numerator is greater than zero.
@frozen public struct StockPrice {
    @usableFromInline let exact: Fraction

    @inlinable public init?(exact: Fraction) {
        guard exact.n > 0 else {
            return nil
        }

        self.exact = exact
    }
}
extension StockPrice {
    @inlinable public func quantity(value: Int64) -> Int64 {
        return value <> (self.exact.d %/ self.exact.n)
    }
    @inlinable public func value(quantity: Int64) -> Int64 {
        return quantity >< self.exact
    }
    @inlinable public func quote(quantity: Int64) -> Quote {
        .init(quantity: quantity, value: self.value(quantity: quantity))
    }
    @inlinable public func quote(value: Int64) -> Quote? {
        guard value > 0 else {
            return nil
        }

        let quantity: Int64 = self.quantity(value: value)

        guard quantity > 0 else {
            return nil
        }

        return .init(quantity: quantity, value: self.value(quantity: quantity))
    }
}
