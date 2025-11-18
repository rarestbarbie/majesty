import Fraction

extension LocalMarket {
    @frozen public struct Interval {
        public var bid: LocalPrice
        public var ask: LocalPrice
        public var supply: Int64
        public var demand: Int64

        @inlinable public init(bid: LocalPrice, ask: LocalPrice, supply: Int64 = 0, demand: Int64 = 0) {
            self.bid = bid
            self.ask = ask
            self.supply = supply
            self.demand = demand
        }
    }
}
extension LocalMarket.Interval {
    @available(*, unavailable)
    public var price: LocalPrice { self.bid }

    var prices: (bid: LocalPrice, ask: LocalPrice) { (self.bid, self.ask) }
}
extension LocalMarket.Interval {
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
