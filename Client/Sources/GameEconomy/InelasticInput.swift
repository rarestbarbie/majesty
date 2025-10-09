@frozen public struct InelasticInput: Identifiable, ResourceInput {
    public let id: Resource

    public var unitsAcquired: Int64
    public var unitsConsumed: Int64
    public var unitsDemanded: Int64
    public var unitsPurchased: Int64

    public var valueAcquired: Int64
    public var valueConsumed: Int64

    @inlinable public init(
        id: Resource,
        unitsAcquired: Int64,
        unitsConsumed: Int64,
        unitsDemanded: Int64,
        unitsPurchased: Int64,
        valueAcquired: Int64,
        valueConsumed: Int64,
    ) {
        self.id = id
        self.unitsAcquired = unitsAcquired
        self.unitsConsumed = unitsConsumed
        self.unitsDemanded = unitsDemanded
        self.unitsPurchased = unitsPurchased
        self.valueAcquired = valueAcquired
        self.valueConsumed = valueConsumed
    }
}
extension InelasticInput: ResourceStockpile {
    @inlinable public init(id: Resource) {
        self.init(
            id: id,
            unitsAcquired: 0,
            unitsConsumed: 0,
            unitsDemanded: 0,
            unitsPurchased: 0,
            valueAcquired: 0,
            valueConsumed: 0
        )
    }
}
extension InelasticInput {
    @inlinable public mutating func turn(unitsDemanded: Int64, efficiency: Double) {
        self.unitsConsumed = 0
        self.unitsDemanded = .init((Double.init(unitsDemanded) * efficiency).rounded(.up))
        self.unitsPurchased = 0
        self.valueConsumed = 0
    }

    /// Inelastic resources can be accumulated over multiple turns, but cannot be stockpiled,
    /// and if they are consumed on a turn, they must be consumed in full.
    mutating func consume() {
        self.unitsConsumed = self.unitsAcquired
        self.unitsAcquired = 0
        self.valueConsumed = self.valueAcquired
        self.valueAcquired = 0
    }

    @inlinable public mutating func report(
        unitsPurchased: Int64,
        valuePurchased: Int64,
    ) {
        self.unitsPurchased = unitsPurchased
        self.unitsAcquired += unitsPurchased
        self.valueAcquired += valuePurchased
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
