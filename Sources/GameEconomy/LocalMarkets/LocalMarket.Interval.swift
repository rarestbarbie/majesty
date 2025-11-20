import D
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
    @inlinable var mid: Fraction {
        let sum: Decimal = self.bid.value + self.ask.value
        switch sum.fraction {
        case (let n, denominator: let d?):
            return n %/ (2 * d)
        case (let n, denominator: nil):
            return n %/ 2
        }
    }

    @inlinable public var spread: Double {
        let bid: Double = Double.init(self.bid.value)
        let ask: Double = Double.init(self.ask.value)
        if  ask > 0 {
            return (ask - bid) / ask
        } else {
            return 0
        }
    }

    var prices: (bid: LocalPrice, ask: LocalPrice) { (self.bid, self.ask) }
}
extension LocalMarket.Interval {
    mutating func update(
        spread: Double?,
        limit: (min: LocalPrice, max: LocalPrice)
    ) {
        defer {
            self.supply = 0
            self.demand = 0
        }

        guard
        let (bid, ask): (bid: LocalPrice, ask: LocalPrice) = self.updated(
            spread: spread,
            limit: limit
        ) else {
            return
        }

        self.bid = bid
        self.ask = ask
    }

    private func updated(
        spread: Double?,
        limit: (min: LocalPrice, max: LocalPrice)
    ) -> (bid: LocalPrice, ask: LocalPrice)? {
        if  self.bid < limit.min {
            return (bid: limit.min, ask: max(limit.min, self.ask))
        } else if
            self.ask > limit.max {
            return (bid: min(limit.max, self.bid), ask: limit.max)
        }

        if  self.supply < self.demand {
            if self.supply == 0 {
                return self.tickedUp(spread: spread, limit: limit.max)
            }
            if (self.demand %/ self.supply) > (LocalPrice.cent %/ (LocalPrice.cent - 1)) {
                return self.tickedUp(spread: spread, limit: limit.max)
            }
        } else if self.bid.value.units > 0,
            self.supply > self.demand {
            if (self.demand %/ self.supply) < ((LocalPrice.cent - 1) %/ LocalPrice.cent) {
                return self.tickedDown(spread: spread, limit: limit.min)
            }
        }

        return nil
    }

    private func tickedUp(spread: Double?, limit: LocalPrice) ->  (bid: LocalPrice, ask: LocalPrice) {
        let ask: LocalPrice = min(self.ask.tickedUp(), limit)

        guard let spread: Double = spread else {
            return (ask, ask)
        }

        let bid: LocalPrice = ask.scaled(by: (1 - spread), rounding: .down)
        return (bid: max(self.bid, bid), ask: ask)
    }

    private func tickedDown(spread: Double?, limit: LocalPrice) -> (bid: LocalPrice, ask: LocalPrice) {
        let bid: LocalPrice = max(self.bid.tickedDown(), limit)

        guard let spread: Double = spread else {
            return (bid, bid)
        }

        let ask: LocalPrice = bid.scaled(by: 1 / (1 - spread), rounding: .up)
        return (bid: bid, ask: min(self.ask, ask))
    }
}
