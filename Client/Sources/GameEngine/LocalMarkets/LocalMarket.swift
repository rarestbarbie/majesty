import GameEconomy

struct LocalMarket<LegalEntity> {
    var yesterday: LocalMarketStats
    var today: LocalMarketStats

    var supply: [Offer]
    var demand: [Offer]

    init(
        yesterday: LocalMarketStats,
        today: LocalMarketStats,
        supply: [Offer],
        demand: [Offer]
    ) {
        self.yesterday = yesterday
        self.today = today
        self.supply = supply
        self.demand = demand
    }

    init() {
        self.yesterday = .init(price: 1, supply: 0, demand: 0)
        self.today = self.yesterday
        self.supply = []
        self.demand = []
    }
}
extension LocalMarket {
    mutating func ask(_ amount: Int64, by entity: LegalEntity) {
        self.supply.append(.init(by: entity, amount: amount))
        self.today.supply += amount
    }
    mutating func bid(_ budget: Int64, by entity: LegalEntity) {
        self.demand.append(.init(by: entity, amount: budget))
        self.today.demand += budget
    }
}
extension LocalMarket {
    mutating func turn() {
        /// To prevent the price from oscillating around a fractional value, we only allow it
        /// to move if the relative deficit, or excess, is greater than the relative change in
        /// the price itself.
        var price: Int64 = self.today.price

        let supply: Int64 = yesterday.price * yesterday.supply
        if  supply < yesterday.demand {
            let incremented: Int64 = yesterday.price + 1
            if (yesterday.demand %/ supply) > (incremented %/ yesterday.price) {
                price = incremented
            }
        } else if yesterday.price > 0,
            supply > yesterday.demand {
            let decremented: Int64 = yesterday.price - 1
            if (yesterday.demand %/ supply) < (decremented %/ yesterday.price) {
                price = decremented
            }
        }

        self.yesterday = self.today
        self.today = .init(price: price)
    }

    mutating func match() {
        self.supply.removeAll(keepingCapacity: true)
        self.demand.removeAll(keepingCapacity: true)

        // TODO: unimplemented
    }
}
