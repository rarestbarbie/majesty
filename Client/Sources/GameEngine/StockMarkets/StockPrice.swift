import GameEconomy

/// A stock price is a fraction whose numerator is greater than zero.
struct StockPrice {
    let exact: Fraction

    init?(exact: Fraction) {
        guard exact.n > 0 else {
            return nil
        }

        self.exact = exact
    }
}
extension StockPrice {
    func quantity(value: Int64) -> Int64 {
        return value <> (self.exact.d %/ self.exact.n)
    }
    func value(quantity: Int64) -> Int64 {
        return quantity >< self.exact
    }
    func quote(quantity: Int64) -> Quote {
        .init(quantity: quantity, value: self.value(quantity: quantity))
    }
    func quote(value: Int64) -> Quote? {
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
