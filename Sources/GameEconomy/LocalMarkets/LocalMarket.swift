import D
import Fraction
import GameIDs
import Random

@frozen public struct LocalMarket: Identifiable {
    public let id: ID
    public var priceFloor: PriceFloor?
    public var yesterday: Interval
    public var today: Interval

    @usableFromInline var asks: [Order]
    @usableFromInline var bids: [Order]

    @inlinable init(
        id: ID,
        priceFloor: PriceFloor?,
        yesterday: Interval,
        today: Interval,
        asks: [Order],
        bids: [Order]
    ) {
        self.id = id
        self.priceFloor = priceFloor
        self.yesterday = yesterday
        self.today = today
        self.asks = asks
        self.bids = bids
    }
}
extension LocalMarket {
    @inlinable init(id: ID) {
        let interval: Interval = .init(price: .init(), supply: 0, demand: 0)
        self.init(
            id: id,
            priceFloor: nil,
            yesterday: interval,
            today: interval,
            asks: [],
            bids: []
        )
    }

    @inlinable public init(state: State) {
        self.init(
            id: state.id,
            priceFloor: state.priceFloor,
            yesterday: state.yesterday,
            today: state.today,
            asks: [],
            bids: []
        )
    }
    @inlinable public var state: State {
        .init(
            id: self.id,
            priceFloor: self.priceFloor,
            yesterday: self.yesterday,
            today: self.today
        )
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

    @inlinable public var history: (yesterday: Interval, today: Interval)  {
        (self.yesterday, self.today)
    }
}
extension LocalMarket {
    public mutating func ask(amount: Int64, by entity: LEI, memo: MineID?) {
        self.asks.append(.init(by: entity, tier: nil, memo: memo, amount: amount))
        self.today.supply += amount
    }

    public mutating func bid(
        budget: Int64,
        by entity: LEI,
        in tier: UInt8,
        limit: Int64,
    ) {
        let quotient: Int64

        switch self.today.price.value.fraction {
        case (let n, denominator: let d?):
            quotient = budget <> (d %/ n)
        case (let n, denominator: nil):
            quotient = budget / n
        }

        let amount: Int64 = min(quotient, limit)
        self.bids.append(.init(by: entity, tier: tier, memo: nil, amount: amount))
        self.today.demand += amount
    }
}
extension LocalMarket {
    public mutating func turn() {
        self.turn(priceFloor: .init(1 %/ 10_000))
        self.priceFloor = nil
    }
    public mutating func turn(priceFloor: LocalPrice, type: PriceFloorType) {
        self.turn(priceFloor: priceFloor)
        self.priceFloor = .init(minimum: priceFloor, type: type)
    }
    private mutating func turn(priceFloor: LocalPrice) {
        let price: LocalPrice = self.today.priceUpdate
        self.yesterday = self.today
        self.today = .init(price: max(price, priceFloor))
    }

    public mutating func match(using random: inout PseudoRandom) -> (
        asks: [Order],
        bids: [Order]
    ) {
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
