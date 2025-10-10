import Fraction

@frozen public struct LocalMarketState {
    public var price: Int64
    public var supply: Int64
    public var demand: Int64

    @inlinable init(price: Int64, supply: Int64 = 0, demand: Int64 = 0) {
        self.price = price
        self.supply = supply
        self.demand = demand
    }
}
extension LocalMarketState {
    /// To prevent the price from oscillating around a fractional value, we only allow it to
    /// move if the relative deficit, or excess, is greater than the relative change in the
    /// price itself.
    var priceChange: Int64 {
        if  self.supply < self.demand {
            if self.supply == 0 {
                return 1
            }
            if (self.demand %/ self.supply) > ((self.price + 1) %/ self.price) {
                return 1
            }
        } else if self.price > 0,
            self.supply > self.demand {
            if (self.demand %/ self.supply) < ((self.price - 1) %/ self.price) {
                return -1
            }
        }

        return 0
    }
}
