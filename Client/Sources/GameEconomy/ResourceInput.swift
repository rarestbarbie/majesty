@frozen public struct Volume {
    public var resource: (i: Int64, o: Int64)
    public var currency: (i: Int64, o: Int64)

    @inlinable public init(
        resource: (i: Int64, o: Int64) = (0, 0),
        currency: (i: Int64, o: Int64) = (0, 0)
    ) {
        self.resource = resource
        self.currency = currency
    }
}

@frozen public struct ResourceInput {
    public let id: Resource

    public var acquiredValue: Int64
    public var acquired: Int64
    public var capacity: Int64
    public var demanded: Int64

    public var consumedValue: Int64
    public var consumed: Int64
    public var purchased: Int64

    @inlinable public init(
        id: Resource,
        acquiredValue: Int64,
        acquired: Int64,
        capacity: Int64,
        demanded: Int64,
        consumedValue: Int64,
        consumed: Int64,
        purchased: Int64,
    ) {
        self.id = id
        self.acquiredValue = acquiredValue
        self.acquired = acquired
        self.capacity = capacity
        self.demanded = demanded
        self.consumedValue = consumedValue
        self.consumed = consumed
        self.purchased = purchased
    }
}
extension ResourceInput: ResourceStockpile {
    @inlinable public init(id: Resource) {
        self.init(
            id: id,
            acquiredValue: 0,
            acquired: 0,
            capacity: 0,
            demanded: 0,
            consumedValue: 0,
            consumed: 0,
            purchased: 0,
        )
    }
}
extension ResourceInput {
    @inlinable public mutating func sync(
        coefficient required: Quantity<Resource>,
        multiplier: Int64,
        stockpile: Int64,
    ) {
        self.demanded = multiplier * required.amount
        self.capacity = stockpile * self.demanded

        self.consumedValue = 0
        self.consumed = 0
        self.purchased = 0
    }

    @inlinable public mutating func sync(
        coefficient required: Quantity<Resource>,
        multiplier: Int64,
        stockpile: Int64,
        efficiency: Double
    ) {
        let demanded: Int64 = multiplier * required.amount
        let capacity: Int64 = stockpile * demanded

        self.demanded = .init((Double.init(demanded) * efficiency).rounded(.up))
        self.capacity = .init((Double.init(capacity) * efficiency).rounded(.up))

        self.consumedValue = 0
        self.consumed = 0
        self.purchased = 0
    }

    /// Returns the approximate value of the resource consumed.
    ///
    /// The “consumed value” is not a real valuation, but merely the fraction of the
    /// acquired value of the resource that was consumed, rounded up to the nearest unit.
    @discardableResult
    @inlinable public mutating func consume(_ amount: Int64, efficiency: Double) -> Int64 {
        let consumed: Int64 = min(
            Int64.init((Double.init(amount) * efficiency).rounded(.up)),
            self.acquired
        )

        self.consumedValue = self.acquired != 0
            ? (consumed %/ self.acquired) *< self.acquiredValue
            : 0

        self.acquiredValue -= self.consumedValue
        self.acquired -= consumed
        self.consumed += consumed

        return consumedValue
    }
}
extension ResourceInput {
    @inlinable public var averageCost: Double {
        let quantity: Int64 = self.acquired + self.consumed
        if  quantity == 0 {
            return 0
        } else {
            return Double.init(self.acquiredValue + self.consumedValue) / Double.init(quantity)
        }
    }

    @inlinable public var fulfilled: Double {
        self.demanded == 0 ? 0 : Double.init(self.acquired) / Double.init(self.demanded)
    }

    @inlinable var needed: Int64 {
        self.needed(self.capacity)
    }

    @inlinable func needed(_ target: Int64) -> Int64 {
        self.acquired < target ? target - self.acquired : 0
    }

    /// Returns the amount of funds actually spent.
    public mutating func buy(
        days stockpile: Int64,
        with budget: Int64,
        in currency: Fiat,
        on exchange: inout Exchange) -> Int64 {
        let target: Int64 = self.demanded * stockpile
        let needed: Int64 = self.needed(target)
        if  needed <= 0 {
            return 0
        }
        if  budget <= 0 {
            return 0
        } else {
            var funds: Int64 = budget
            let acquired: Int64 = exchange[self.id / currency].buy(needed, with: &funds)
            let fundsSpent: Int64 = budget - funds

            self.purchased += acquired
            self.acquired += acquired
            self.acquiredValue += fundsSpent
            return fundsSpent
        }
    }
}

#if TESTABLE
extension ResourceInput: Equatable, Hashable {}
#endif
