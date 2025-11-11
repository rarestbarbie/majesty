import D
import Fraction
import GameIDs
import Random

@frozen public struct LocalMarket: Identifiable {
    public let id: ID
    public var yesterday: Interval
    public var today: Interval
    public var limit: (
        min: LocalPriceLevel?,
        max: LocalPriceLevel?
    )

    @usableFromInline var asks: [Order]
    @usableFromInline var bids: [Order]

    @inlinable init(
        id: ID,
        yesterday: Interval,
        today: Interval,
        limit: (
            min: LocalPriceLevel?,
            max: LocalPriceLevel?
        ),
        asks: [Order],
        bids: [Order]
    ) {
        self.id = id
        self.yesterday = yesterday
        self.today = today
        self.limit = limit
        self.asks = asks
        self.bids = bids
    }
}
extension LocalMarket {
    @inlinable init(id: ID) {
        let interval: Interval = .init(price: .init(), supply: 0, demand: 0)
        self.init(
            id: id,
            yesterday: interval,
            today: interval,
            limit: (min: nil, max: nil),
            asks: [],
            bids: []
        )
    }

    @inlinable public init(state: State) {
        self.init(
            id: state.id,
            yesterday: state.yesterday,
            today: state.today,
            limit: state.limit,
            asks: [],
            bids: []
        )
    }
    @inlinable public var state: State {
        .init(
            id: self.id,
            yesterday: self.yesterday,
            today: self.today,
            limit: self.limit,
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
    private static var minDefault: LocalPrice { .init(1 %/ 10_000) }
    private static var maxDefault: LocalPrice { .init(100_000_000 %/ 1) }
}
extension LocalMarket {
    public mutating func turn(
        priceControls: (min: LocalPriceLevel?, max: LocalPriceLevel?)
    ) {
        self.turn(
            priceControls: (
                priceControls.min?.price ?? Self.minDefault,
                priceControls.max?.price ?? Self.maxDefault
            )
        )
        self.limit = priceControls
    }
    private mutating func turn(priceControls: (min: LocalPrice, max: LocalPrice)) {
        let price: LocalPrice = self.today.priceUpdate

        self.yesterday = self.today

        if  price < priceControls.min {
            self.today = .init(price: priceControls.min)
        } else if price > priceControls.max {
            self.today = .init(price: priceControls.max)
        } else {
            self.today = .init(price: price)
        }
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
