@frozen public struct InelasticInput: Identifiable, ResourceInput {
    public let id: Resource

    public var unitsDemanded: Int64
    public var unitsConsumed: Int64
    public var valueConsumed: Int64
    // public var price: Int64

    @inlinable public init(
        id: Resource,
        unitsDemanded: Int64,
        unitsConsumed: Int64,
        valueConsumed: Int64,
        // price: Int64
    ) {
        self.id = id
        self.unitsDemanded = unitsDemanded
        self.unitsConsumed = unitsConsumed
        self.valueConsumed = valueConsumed
        // self.price = price
    }
}
extension InelasticInput: ResourceStockpile {
    @inlinable public init(id: Resource) {
        self.init(
            id: id,
            unitsDemanded: 0,
            unitsConsumed: 0,
            valueConsumed: 0,
            // price: 0
        )
    }
}
extension InelasticInput {
    @inlinable public mutating func turn(unitsDemanded: Int64, efficiency: Double) {
        self.unitsDemanded = .init((Double.init(unitsDemanded) * efficiency).rounded(.up))
        self.unitsConsumed = 0
        self.valueConsumed = 0
    }

    @inlinable public mutating func report(
        unitsConsumed: Int64,
        valueConsumed: Int64,
        // price: Int64
    ) {
        self.unitsConsumed = unitsConsumed
        self.valueConsumed = valueConsumed
        // self.price = price
    }
}
extension InelasticInput {
    @inlinable public var fulfilled: Double {
        self.unitsDemanded == 0
            ? 0
            : Double.init(self.unitsConsumed) / Double.init(self.unitsDemanded)
    }

    @inlinable public var averageCost: Double {
        self.unitsConsumed == 0 ? 0 : Double.init(
            self.valueConsumed
        ) / Double.init(
            self.unitsConsumed
        )
    }
}

#if TESTABLE
extension InelasticInput: Equatable, Hashable {}
#endif
