import GameEconomy
import Random

struct LocalMarket<LegalEntity> {
    var yesterday: LocalMarketStats
    var today: LocalMarketStats

    var asks: [Order]
    var bids: [Order]

    init(
        yesterday: LocalMarketStats,
        today: LocalMarketStats,
        asks: [Order],
        bids: [Order]
    ) {
        self.yesterday = yesterday
        self.today = today
        self.asks = asks
        self.bids = bids
    }

    init() {
        self.yesterday = .init(price: 1, supply: 0, demand: 0)
        self.today = self.yesterday
        self.asks = []
        self.bids = []
    }
}
extension LocalMarket {
    var price: Candle<Int64> {
        .init(
            o: yesterday.price,
            l: min(yesterday.price, today.price),
            h: max(yesterday.price, today.price),
            c: today.price,
        )
    }
}
extension LocalMarket {
    mutating func ask(amount: Int64, by entity: LegalEntity) {
        self.asks.append(.init(by: entity, tier: nil, amount: amount))
        self.today.supply += amount
    }

    mutating func bid(
        budget: Int64,
        by entity: LegalEntity,
        in tier: ResourceTierIdentifier,
        limit: Int64,
    ) {
        let amount: Int64 = min(budget / self.today.price, limit)
        self.bids.append(.init(by: entity, tier: tier, amount: amount))
        self.today.demand += amount
    }
}
extension LocalMarket {
    mutating func turn() {
        let price: Int64 = self.today.price + self.today.priceChange
        self.yesterday = self.today
        self.today = .init(price: price)
    }

    mutating func match(using random: inout PseudoRandom) -> (asks: [Order], bids: [Order]) {
        if self.today.supply > self.today.demand {
            self.asks.shuffle(using: &random.generator)

            guard let matched: [Int64] = self.asks.distribute(
                self.today.demand,
                share: \.amount
            ) else {
                // nonzero supply, but no asks?
                fatalError("unreachable")
            }

            for i: Int in self.asks.indices {
                self.asks[i].filled = matched[i]
            }
            for i: Int in self.bids.indices {
                self.bids[i].fillAll()
            }
        } else if self.today.supply < self.today.demand {
            self.bids.shuffle(using: &random.generator)

            guard let matched: [Int64] = self.bids.distribute(
                self.today.supply,
                share: \.amount
            ) else {
                // nonzero demand, but no bids?
                fatalError("unreachable")
            }

            for i: Int in self.bids.indices {
                self.bids[i].filled = matched[i]
            }
            for i: Int in self.asks.indices {
                self.asks[i].fillAll()
            }
        } else {
            for i: Int in self.asks.indices {
                self.asks[i].fillAll()
            }
            for i: Int in self.bids.indices {
                self.bids[i].fillAll()
            }
        }

        defer {
            self.asks = []
            self.bids = []
        }

        return (asks: self.asks, bids: self.bids)
    }
}
