public protocol ResourceInput: ResourceStockpile {
    var unitsAcquired: Int64 { get }
    var unitsConsumed: Int64 { get }
    var unitsDemanded: Int64 { get }
    var unitsPurchased: Int64 { get }

    var valueAcquired: Int64 { get }
    var valueConsumed: Int64 { get }
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
        self.unitsDemanded == 0
            ? 0
            : Double.init(self.unitsAcquired) / Double.init(self.unitsDemanded)
    }
}
