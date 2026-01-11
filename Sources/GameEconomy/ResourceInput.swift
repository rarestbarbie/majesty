import Fraction
import GameIDs

@frozen public struct ResourceInput: Identifiable {
    public let id: Resource

    public var unitsDemanded: Int64
    /// Negative if units were returned to the market.
    public var unitsReturned: Int64
    public var units: Reservoir

    /// The “consumed value” is not a real valuation, but merely the fraction of the
    /// unitsAcquired value of the resource that was consumed, rounded up to the nearest unit.
    public var value: Reservoir
    // public var valueAtMarket: Valuation

    /// Most recent available price, can be different from average cost.
    public var price: Double?

    @inlinable public init(
        id: Resource,
        unitsDemanded: Int64,
        unitsReturned: Int64,
        units: Reservoir,
        value: Reservoir,
        price: Double?
    ) {
        self.id = id
        self.unitsDemanded = unitsDemanded
        self.unitsReturned = unitsReturned
        self.units = units
        self.value = value
        self.price = price
    }
}
extension ResourceInput: ResourceStockpile {
    @inlinable public init(id: Resource) {
        self.init(
            id: id,
            unitsDemanded: 0,
            unitsReturned: 0,
            units: .zero,
            value: .zero,
            price: nil
        )
    }
}
extension ResourceInput {
    @inlinable public var unitsConsumed: Int64 {
        self.units.removed + self.unitsReturned
    }

    @inlinable public var valueConsumed: Int64 {
        self.value.removed
    }

    mutating func turn(
        unitsDemanded: Int64,
        efficiency: Double
    ) {
        self.unitsDemanded = .init((Double.init(unitsDemanded) * efficiency).rounded(.up))
        self.unitsReturned = 0
        self.units.turn()
        self.value.turn()
    }
}
extension ResourceInput {
    @inlinable public mutating func capture(
        unitsPurchased: inout Int64,
        valuePurchased: inout Int64,
    ) {
        let unitsCaptured: Int64 = min(self.needed(self.unitsDemanded), unitsPurchased)
        if  unitsCaptured == 0 {
            return
        }

        let valueCaptured: Int64 = valuePurchased <> (unitsCaptured %/ unitsPurchased)

        self.report(
            unitsPurchased: unitsCaptured,
            valuePurchased: valueCaptured
        )

        unitsPurchased -= unitsCaptured
        valuePurchased -= valueCaptured
    }

    @inlinable public mutating func report(
        unitsPurchased: Int64,
        valuePurchased: Int64,
    ) {
        self.units += unitsPurchased
        self.value += valuePurchased
        self.price = unitsPurchased != 0 ? Double.init(valuePurchased %/ unitsPurchased) : nil
    }
}
extension ResourceInput {
    /// Returns the amount of funds actually spent, negative if funds were spent, positive
    /// if funds were refunded.
    mutating func trade(
        stockpileDaysTarget: Int64,
        stockpileDaysReturn: Int64,
        budget: Int64,
        in currency: CurrencyID,
        on exchange: inout WorldMarkets
    ) -> Int64 {
        {
            let target: Int64 = self.unitsDemanded * stockpileDaysTarget
            let limit: Int64 = self.unitsDemanded * stockpileDaysReturn

            if  limit < self.units.total {
                // We actually have too much of the resource, and need to sell some off.
                var unitsExceeded: Int64 = self.units.total - limit
                let valueRefunded: Int64 = $0.sell(&unitsExceeded)
                let unitsSold: Int64 = self.units.total - limit - unitsExceeded

                self.units -= unitsSold
                self.unitsReturned -= unitsSold

                // when this happens, it’s a good idea to also re-appraise the market value
                // of the entire resource stockpile, which we woudn’t normally do otherwise
                let price: Double = $0.price
                self.value.untracked = Int64.init(Double.init(self.units.total) * price)
                self.price = price

                return valueRefunded
            } else {
                let needed: Int64 = target - self.units.total
                if  needed <= 0 {
                    self.price = $0.price
                    return 0
                }
                if  budget <= 0 {
                    self.price = $0.price
                    return 0
                } else {
                    var funds: Int64 = budget
                    let unitsAcquired: Int64 = $0.buy(needed, with: &funds)
                    let fundsSpent: Int64 = budget - funds

                    self.units += unitsAcquired
                    self.value += fundsSpent

                    // Compute actual price, if at least one unit was purchased, otherwise
                    // theoretical market price
                    self.price = unitsAcquired != 0
                        ? Double.init(fundsSpent %/ unitsAcquired)
                        : $0.price
                    return -fundsSpent
                }
            }
        } (&exchange[self.id / currency])
    }
}
extension ResourceInput {
    mutating func consume(_ amount: Int64, efficiency: Double, reservedDays: Int64) {
        let unitsConsumed: Int64 = min(
            Int64.init((Double.init(amount) * efficiency).rounded(.up)),
            reservedDays <= 1 ? self.units.total : self.units.total / reservedDays
        )

        /// the precise (integral) formula is
        /// Δv = floor((Δu %/ u) * v)
        let valueConsumed: Int64 = self.units.total != 0
            ? (unitsConsumed %/ self.units.total) <> self.value.total
            : 0

        self.value -= valueConsumed
        self.units -= unitsConsumed
    }

    mutating func consumeAll() {
        self.units -= self.units.total
        self.value -= self.value.total
    }
}
extension ResourceInput {
    @inlinable public func needed(_ target: Int64) -> Int64 {
        self.units.total < target ? target - self.units.total : 0
    }

    @inlinable public var averageCost: Double? {
        let denominator: Int64 = self.units.total + self.unitsConsumed
        return denominator == 0 ? nil : Double.init(
            self.valueConsumed + self.value.total
        ) / Double.init(denominator)
    }

    var fulfilled: Double {
        let denominator: Int64 = self.unitsDemanded
        return denominator == 0 ? 0 : Double.init(
            self.unitsConsumed + self.units.total
        ) / Double.init(denominator)
    }
    var fulfilledAfterReservation: Double {
        let denominator: Int64 = self.unitsDemanded
        return denominator == 0 ? 0 : Double.init(
            self.unitsConsumed
        ) / Double.init(denominator)
    }
}

#if TESTABLE
extension ResourceInput: Equatable, Hashable {}
#endif
