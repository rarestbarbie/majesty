@frozen public struct TradeableInput: Identifiable {
    public let id: Resource

    public var unitsAcquired: Int64
    public var unitsConsumed: Int64
    public var unitsDemanded: Int64
    public var unitsPurchased: Int64
    public var unitsReturned: Int64

    public var valueAcquired: Int64
    /// The “consumed value” is not a real valuation, but merely the fraction of the
    /// unitsAcquired value of the resource that was consumed, rounded up to the nearest unit.
    public var valueConsumed: Int64

    public var price: Double

    @inlinable public init(
        id: Resource,
        unitsAcquired: Int64,
        unitsConsumed: Int64,
        unitsDemanded: Int64,
        unitsPurchased: Int64,
        unitsReturned: Int64,
        valueAcquired: Int64,
        valueConsumed: Int64,
        price: Double
    ) {
        self.id = id
        self.unitsAcquired = unitsAcquired
        self.unitsConsumed = unitsConsumed
        self.unitsDemanded = unitsDemanded
        self.unitsPurchased = unitsPurchased
        self.unitsReturned = unitsReturned
        self.valueAcquired = valueAcquired
        self.valueConsumed = valueConsumed
        self.price = price
    }
}
extension TradeableInput: ResourceStockpile, ResourceInput {
    @inlinable public init(id: Resource) {
        self.init(
            id: id,
            unitsAcquired: 0,
            unitsConsumed: 0,
            unitsDemanded: 0,
            unitsPurchased: 0,
            unitsReturned: 0,
            valueAcquired: 0,
            valueConsumed: 0,
            price: 0,
        )
    }
}
extension TradeableInput {
    mutating func turn(
        unitsDemanded: Int64,
        stockpileDays: Int64,
        efficiency: Double
    ) {
        self.unitsDemanded = .init((Double.init(unitsDemanded) * efficiency).rounded(.up))
        self.valueConsumed = 0
        self.unitsConsumed = 0
        self.unitsPurchased = 0
        self.unitsReturned = 0
    }
}
extension TradeableInput {
    /// Returns the amount of funds actually spent.
    mutating func trade(
        stockpileDays: ClosedRange<Int64>,
        budget: Int64,
        in currency: Fiat,
        on exchange: inout Exchange
    ) -> Int64 {
        {
            let target: Int64 = self.unitsDemanded * stockpileDays.lowerBound
            let limit: Int64 = self.unitsDemanded * stockpileDays.upperBound

            if  limit < self.unitsAcquired {
                // We actually have too much of the resource, and need to sell some off.
                var unitsExceeded: Int64 = self.unitsAcquired - limit
                let valueRefunded: Int64 = $0.sell(&unitsExceeded)
                let unitsSold: Int64 = self.unitsAcquired - limit - unitsExceeded

                self.price = $0.price

                if  unitsSold > 0 {
                    let writedown: Fraction = (unitsSold %/ self.unitsAcquired)
                    self.valueAcquired -= self.valueAcquired <> writedown
                    self.unitsAcquired -= unitsSold
                    self.unitsReturned -= unitsSold
                }

                return valueRefunded
            } else {
                let needed: Int64 = target - self.unitsAcquired
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

                    self.unitsPurchased += unitsAcquired
                    self.unitsAcquired += unitsAcquired
                    self.valueAcquired += fundsSpent

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

#if TESTABLE
extension TradeableInput: Equatable, Hashable {}
#endif
