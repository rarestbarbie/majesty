public protocol ResourceInput: ResourceStockpile {
    var unitsAcquired: Int64 { get set }
    var unitsConsumed: Int64 { get set }
    var unitsDemanded: Int64 { get }
    var unitsPurchased: Int64 { get }

    var valueAcquired: Int64 { get set }
    var valueConsumed: Int64 { get set }
}
extension ResourceInput {
    mutating func consume(_ amount: Int64, efficiency: Double) {
        let unitsAcquired: Int64 = self.unitsAcquired
        let valueAcquired: Int64 = self.valueAcquired

        let unitsConsumed: Int64 = min(
            Int64.init((Double.init(amount) * efficiency).rounded(.up)),
            unitsAcquired
        )

        let valueConsumed: Int64 = unitsAcquired != 0
            ? (unitsConsumed %/ unitsAcquired) <> valueAcquired
            : 0

        self.valueAcquired = valueAcquired - valueConsumed
        self.unitsAcquired = unitsAcquired - unitsConsumed

        self.valueConsumed += valueConsumed
        self.unitsConsumed += unitsConsumed
    }

    mutating func consumeAll() {
        self.unitsConsumed = self.unitsAcquired
        self.unitsAcquired = 0
        self.valueConsumed = self.valueAcquired
        self.valueAcquired = 0
    }
}
extension ResourceInput {
    @inlinable public func needed(_ target: Int64) -> Int64 {
        self.unitsAcquired < target ? target - self.unitsAcquired : 0
    }

    @inlinable public var averageCost: Double {
        let quantity: Int64 = self.unitsAcquired + self.unitsConsumed
        if  quantity == 0 {
            return 0
        } else {
            return Double.init(self.valueAcquired + self.valueConsumed) / Double.init(quantity)
        }
    }

    @inlinable public var fulfilled: Double {
        let denominator: Int64 = self.unitsDemanded
        return denominator == 0 ? 0 : Double.init(
            self.unitsAcquired + self.unitsConsumed
        ) / Double.init(denominator)
    }
}
