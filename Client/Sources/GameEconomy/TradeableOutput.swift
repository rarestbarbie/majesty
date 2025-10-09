@frozen public struct TradeableOutput: Identifiable {
    public let id: Resource
    public var unitsProduced: Int64
    public var unitsSold: Int64
    public var valueSold: Int64
    public var price: Double

    @inlinable public init(
        id: Resource,
        unitsProduced: Int64,
        unitsSold: Int64,
        valueSold: Int64,
        price: Double
    ) {
        self.id = id
        self.unitsProduced = unitsProduced
        self.unitsSold = unitsSold
        self.valueSold = valueSold
        self.price = price
    }
}
extension TradeableOutput: ResourceStockpile {
    @inlinable public init(id: Resource) {
        self.init(
            id: id,
            unitsProduced: 0,
            unitsSold: 0,
            valueSold: 0,
            price: 0
        )
    }
}
extension TradeableOutput {
    mutating func deposit(unitsProduced: Int64, efficiency: Double) {
        self.unitsProduced = Int64.init((Double.init(unitsProduced) * efficiency))
        self.unitsSold = 0
        self.valueSold = 0
    }

    public mutating func sell(in currency: Fiat, on exchange: inout Exchange) -> Int64 {
        {
            let units: Int64 = self.unitsProduced - self.unitsSold
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
extension TradeableOutput: Equatable, Hashable {}
#endif
