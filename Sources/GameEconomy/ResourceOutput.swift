import Fraction
import GameIDs
import Random

@frozen public struct ResourceOutput: Identifiable {
    public let id: Resource
    public var units: Reservoir
    public var unitsSold: Int64
    public var valueSold: Int64
    /// Theoretical estimate of market value of resources produced this turn. For tradeable
    /// goods, this will almost always be overly optimistic on firm startup, as it ignores
    /// slippage. After the first market sale, the previous sale price is used instead, which
    /// will often be more realistic.
    public var valueProduced: Int64
    /// Similar to ``valueProduced``, estimates the market value of ``units.total``.
    public var valueEstimate: Int64

    /// Most recent available price, can be different from average cost.
    public var price: Double?

    @inlinable public init(
        id: Resource,
        units: Reservoir,
        unitsSold: Int64,
        valueSold: Int64,
        valueProduced: Int64,
        valueEstimate: Int64,
        price: Double?
    ) {
        self.id = id
        self.units = units
        self.unitsSold = unitsSold
        self.valueSold = valueSold
        self.valueProduced = valueProduced
        self.valueEstimate = valueEstimate
        self.price = price
    }
}
extension ResourceOutput: ResourceStockpile {
    @inlinable public init(id: Resource) {
        self.init(
            id: id,
            units: .zero,
            unitsSold: 0,
            valueSold: 0,
            valueProduced: 0,
            valueEstimate: 0,
            price: nil
        )
    }
}
extension ResourceOutput {
    mutating func turn() {
        self.units.turn()
        self.unitsSold = 0
        self.valueSold = 0
        self.valueProduced = 0
    }

    mutating func produce(_ amount: Int64, efficiency: Double) {
        let units: Int64 = .init(Double.init(amount) * efficiency)
        self.units.wash(units)
    }
    mutating func deposit(_ amount: Int64, efficiency: Double) {
        self.units += .init(Double.init(amount) * efficiency)
    }
}
extension ResourceOutput {
    /// Report the number of units sold and proceeds received from a local resource sale.
    /// This method must be called only once per turn.
    @inlinable public mutating func report(
        unitsSold: Int64,
        valueSold: Int64,
    ) {
        // Local resources never have stockpile value.
        self.valueEstimate = 0
        // For local resources, value is not said to be produced until it has already been
        // matched with a buyer. This means crafted goods only count towards profit margins
        // after they go through the maturation pipeline, if the goods are local. This is
        // different from tradeable goods, which count as produced as soon as they are made.
        self.valueProduced = valueSold
        self.valueSold = valueSold
        self.unitsSold = unitsSold
        self.price = unitsSold != 0 ? Double.init(valueSold %/ unitsSold) : nil
    }
}
extension ResourceOutput {
    mutating func sell(
        in currency: CurrencyID,
        to exchange: inout WorldMarkets,
    ) -> Int64 {
        self.sell(units: self.units.total, in: currency, to: &exchange)
    }

    mutating func sell(
        in currency: CurrencyID,
        to exchange: inout WorldMarkets,
        random: inout PseudoRandom
    ) -> Int64 {
        self.units.total > 0 ? self.sell(
            units: .random(in: 0 ... self.units.total, using: &random.generator),
            in: currency,
            to: &exchange
        ) : 0
    }

    mutating func mark(
        in currency: CurrencyID,
        to exchange: borrowing WorldMarkets
    ) {
        // if we previously recorded a price, use it for theoretical calculation,
        // otherwise use the (optimistic) market mid price
        let price: Double = self.price ?? exchange[self.id / currency].price
        self.mark(to: price)
    }
}
extension ResourceOutput {
    private mutating func sell(
        units unitsAvailable: Int64,
        in currency: CurrencyID,
        to exchange: inout WorldMarkets
    ) -> Int64 {
        var unitsRemaining: Int64 = unitsAvailable
        if  unitsRemaining > 0 {
            let valueSold: Int64 = exchange[self.id / currency].sell(&unitsRemaining)
            let unitsSold: Int64 = unitsAvailable - unitsRemaining

            self.units -= unitsAvailable
            self.unitsSold = unitsSold
            self.valueSold = valueSold
            // we drained any unsold units, so value estimate is now zero
            self.valueEstimate = 0

            // if goods were produced, but no units could be sold, the effective price is 0
            let price: Double = unitsSold != 0 ? Double.init(valueSold %/ unitsSold) : 0
            self.mark(to: price)
            return valueSold
        } else {
            self.mark(in: currency, to: exchange)
            return 0
        }
    }

    private mutating func mark(to price: Double) {
        self.price = price
        self.valueProduced = Int64.init(Double.init(self.units.added) * price)
        self.valueEstimate = Int64.init(Double.init(self.units.total) * price)
    }
}

#if TESTABLE
extension ResourceOutput: Equatable, Hashable {}
#endif
