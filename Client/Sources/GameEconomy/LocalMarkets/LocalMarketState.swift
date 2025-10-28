import Fraction

@frozen public struct LocalMarketState {
    public var price: LocalPrice
    public var supply: Int64
    public var demand: Int64

    @inlinable init(price: LocalPrice, supply: Int64 = 0, demand: Int64 = 0) {
        self.price = price
        self.supply = supply
        self.demand = demand
    }
}
extension LocalMarketState {
    /// To prevent the price from oscillating around a fractional value, we only allow it to
    /// move if the relative deficit, or excess, is greater than the relative change in the
    /// price itself.
    var priceUpdate: LocalPrice {
        if  self.supply < self.demand {
            if self.supply == 0 {
                return self.price.tickedUp()
            }
            if (self.demand %/ self.supply) > (LocalPrice.cent %/ (LocalPrice.cent - 1)) {
                return self.price.tickedUp()
            }
        } else if self.price.value.units > 0,
            self.supply > self.demand {
            if (self.demand %/ self.supply) < ((LocalPrice.cent - 1) %/ LocalPrice.cent) {
                return self.price.tickedDown()
            }
        }

        return self.price
    }
}
