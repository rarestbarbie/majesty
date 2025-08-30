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
