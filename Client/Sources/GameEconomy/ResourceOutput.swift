import Fraction
import GameIDs

@frozen public struct ResourceOutput<Price>: Identifiable where Price: Equatable & Hashable {
    public let id: Resource
    public var units: Reservoir
    public var unitsSold: Int64
    public var valueSold: Int64
    public var price: Price?

    @inlinable public init(
        id: Resource,
        units: Reservoir,
        unitsSold: Int64,
        valueSold: Int64,
        price: Price?
    ) {
        self.id = id
        self.units = units
        self.unitsSold = unitsSold
        self.valueSold = valueSold
        self.price = price
    }
}
extension ResourceOutput: ResourceStockpile {
    @inlinable public init(id: Resource) {
        self.init(id: id, units: .zero, unitsSold: 0, valueSold: 0, price: nil)
    }
}
extension ResourceOutput {
    @inlinable public var unitsReleased: Int64 {
        self.units.removed - self.unitsSold
    }

    mutating func turn(releasing fraction: Fraction) {
        self.units.turn()
        // is `min` necessary here?
        self.units -= min(self.units.total, self.units.total >< fraction)
        self.unitsSold = 0
        self.valueSold = 0
    }

    mutating func deposit(_ amount: Int64, efficiency: Double) {
        self.units += .init(Double.init(amount) * efficiency)
    }
}
extension ResourceOutput<Never> {
    @inlinable public mutating func report(
        unitsSold: Int64,
        valueSold: Int64,
    ) {
        self.unitsSold += unitsSold
        self.valueSold += valueSold
    }
}
extension ResourceOutput<Double> {
    public mutating func sell(in currency: Fiat, on exchange: inout Exchange) -> Int64 {
        {
            let units: Int64 = self.units.removed - self.unitsSold
            var unitsRemaining: Int64 = units
            if  unitsRemaining > 0 {
                let value: Int64 = $0.sell(&unitsRemaining)
                let unitsSold: Int64 = units - unitsRemaining
                self.unitsSold += unitsSold
                self.valueSold += value

                self.price = units != 0
                    ? Double.init(value %/ unitsSold)
                    : $0.price
                return value
            } else {
                self.price = $0.price
                return 0
            }
        } (&exchange[self.id / currency])
    }
}

#if TESTABLE
extension ResourceOutput: Equatable, Hashable {}
#endif
