import D
import GameIDs
import Random

@frozen public struct LocalMarket {
    public var priceFloor: PriceFloor?
    public var yesterday: LocalMarketState
    public var today: LocalMarketState

    @usableFromInline var asks: [Order]
    @usableFromInline var bids: [Order]

    init(
        priceFloor: PriceFloor?,
        yesterday: LocalMarketState,
        today: LocalMarketState,
        asks: [Order],
        bids: [Order]
    ) {
        self.priceFloor = priceFloor
        self.yesterday = yesterday
        self.today = today
        self.asks = asks
        self.bids = bids
    }

    @inlinable init() {
        self.priceFloor = nil
        self.yesterday = .init(price: .init(per100: 1), supply: 0, demand: 0)
        self.today = self.yesterday
        self.asks = []
        self.bids = []
    }
}
extension LocalMarket {
    @inlinable public var price: Candle<LocalPrice> {
        .init(
            o: yesterday.price,
            l: min(yesterday.price, today.price),
            h: max(yesterday.price, today.price),
            c: today.price,
        )
    }

    @inlinable public var history: (yesterday: LocalMarketState, today: LocalMarketState)  {
        (self.yesterday, self.today)
    }
}
extension LocalMarket {
    public mutating func ask(amount: Int64, by entity: LEI) {
        self.asks.append(.init(by: entity, tier: nil, amount: amount))
        self.today.supply += amount
    }

    public mutating func bid(
        budget: Int64,
        by entity: LEI,
        in tier: UInt8,
        limit: Int64,
    ) {
        let amount: Int64 = min(budget * 100 / self.today.price.per100, limit)
        self.bids.append(.init(by: entity, tier: tier, amount: amount))
        self.today.demand += amount
    }
}
extension LocalMarket {
    public mutating func turn() {
        self.turn(priceFloor: .zero)
        self.priceFloor = nil
    }
    public mutating func turn(priceFloor: LocalPrice, type: PriceFloorType) {
        self.turn(priceFloor: priceFloor)
        self.priceFloor = .init(minimum: priceFloor, type: type)
    }
    private mutating func turn(priceFloor: LocalPrice) {
        let price: LocalPrice = .init(per100: self.today.price.per100 + self.today.priceChange)
        self.yesterday = self.today
        self.today = .init(price: max(price, priceFloor))
    }

    public mutating func match(using random: inout PseudoRandom) -> (asks: [Order], bids: [Order]) {
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
