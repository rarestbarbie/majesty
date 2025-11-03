import Fraction
import GameIDs

@available(*, deprecated)
public typealias InelasticInput = ResourceInput<Never>
@available(*, deprecated)
public typealias TradeableInput = ResourceInput<Double>

@frozen public struct ResourceInput<Price>: Identifiable where Price: Equatable & Hashable {
    public let id: Resource

    public var unitsDemanded: Int64
    /// Negative if units were returned to the market.
    public var unitsReturned: Int64
    public var units: Reservoir

    public var valueReturned: Int64
    /// The “consumed value” is not a real valuation, but merely the fraction of the
    /// unitsAcquired value of the resource that was consumed, rounded up to the nearest unit.
    public var value: Reservoir
    // public var valueAtMarket: Valuation

    public var price: Price?

    @inlinable public init(
        id: Resource,
        unitsDemanded: Int64,
        unitsReturned: Int64,
        units: Reservoir,
        valueReturned: Int64,
        value: Reservoir,
        price: Price?
    ) {
        self.id = id
        self.unitsDemanded = unitsDemanded
        self.unitsReturned = unitsReturned
        self.units = units
        self.valueReturned = valueReturned
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
            valueReturned: 0,
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
        self.value.removed + self.valueReturned
    }

    mutating func turn(
        unitsDemanded: Int64,
        efficiency: Double
    ) {
        self.unitsDemanded = .init((Double.init(unitsDemanded) * efficiency).rounded(.up))
        self.unitsReturned = 0
        self.units.turn()

        self.valueReturned = 0
        self.value.turn()
        // self.valueAtMarket.turn()
    }
}
extension ResourceInput<Never> {
    @inlinable public mutating func report(
        unitsPurchased: Int64,
        valuePurchased: Int64,
    ) {
        self.units += unitsPurchased
        self.value += valuePurchased
    }
}
extension ResourceInput<Double> {
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

            if  limit < self.units.total {
                // We actually have too much of the resource, and need to sell some off.
                var unitsExceeded: Int64 = self.units.total - limit
                let valueRefunded: Int64 = $0.sell(&unitsExceeded)
                let unitsSold: Int64 = self.units.total - limit - unitsExceeded

                self.price = $0.price

                if  unitsSold > 0 {
                    let writedown: Fraction = (unitsSold %/ self.units.total)
                    let valueReturned: Int64 = self.value.total <> writedown

                    self.units -= unitsSold
                    self.unitsReturned -= unitsSold

                    self.value -= valueReturned
                    self.valueReturned -= valueReturned
                }

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
    mutating func consume(_ amount: Int64, efficiency: Double) {
        let unitsConsumed: Int64 = min(
            Int64.init((Double.init(amount) * efficiency).rounded(.up)),
            self.units.total
        )

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

    @inlinable public var fulfilled: Double {
        let denominator: Int64 = self.unitsDemanded
        return denominator == 0 ? 0 : Double.init(
            self.unitsConsumed + self.units.total
        ) / Double.init(denominator)
    }
}

#if TESTABLE
extension ResourceInput: Equatable, Hashable {}
#endif
