@frozen public struct ResourceOutput {
    public let id: Resource
    public var quantity: Int64
    public var leftover: Int64
    public var proceeds: Int64

    @inlinable public init(
        id: Resource,
        quantity: Int64,
        leftover: Int64,
        proceeds: Int64
    ) {
        self.id = id
        self.quantity = quantity
        self.leftover = leftover
        self.proceeds = proceeds
    }

}
extension ResourceOutput: ResourceStockpile {
    @inlinable public init(id: Resource) {
        self.init(
            id: id,
            quantity: 0,
            leftover: 0,
            proceeds: 0
        )
    }
}
extension ResourceOutput {
    @inlinable public mutating func deposit(_ amount: Int64, efficiency: Double) {
        let produced: Int64 = .init(Double.init(amount) * efficiency)
        self.quantity = produced
        self.leftover = produced
        self.proceeds = 0
    }
}
extension ResourceOutput {
    public mutating func sell(
        in currency: Fiat,
        on exchange: inout Exchange,
    ) -> Int64 {
        if  0 < self.leftover {
            self.proceeds = exchange[self.id / currency].sell(&self.leftover)
        } else {
            self.proceeds = 0
        }

        return self.proceeds
    }
}

#if TESTABLE
extension ResourceOutput: Equatable, Hashable {}
#endif
