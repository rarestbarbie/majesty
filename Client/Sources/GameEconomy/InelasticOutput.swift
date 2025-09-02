@frozen public struct InelasticOutput: Identifiable {
    public let id: Resource
    public var unitsProduced: Int64
    public var unitsSold: Int64
    public var valueSold: Int64
    // public var price: Int64

    @inlinable public init(
        id: Resource,
        unitsProduced: Int64,
        unitsSold: Int64,
        valueSold: Int64,
        // price: Int64
    ) {
        self.id = id
        self.unitsProduced = unitsProduced
        self.unitsSold = unitsSold
        self.valueSold = valueSold
        // self.price = price
    }
}
extension InelasticOutput: ResourceStockpile {
    @inlinable public init(id: Resource) {
        self.init(id: id, unitsProduced: 0, unitsSold: 0, valueSold: 0)
    }
}
extension InelasticOutput {
    mutating func turn(unitsProduced: Int64, efficiency: Double) {
        self.unitsProduced = .init(Double.init(unitsProduced) * efficiency)
        self.unitsSold = 0
        self.valueSold = 0
    }

    @inlinable public mutating func report(
        unitsSold: Int64,
        valueSold: Int64,
    ) {
        self.unitsSold = unitsSold
        self.valueSold = valueSold
        // self.price = price
    }
}

#if TESTABLE
extension InelasticOutput: Equatable, Hashable {}
#endif
