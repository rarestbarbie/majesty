import D
import Fraction
import GameIDs
import Random

@frozen public struct LocalMarket: Identifiable {
    public let id: ID
    public var stabilizationFund: Reservoir
    public var stockpile: Reservoir
    public var yesterday: Interval
    public var today: Interval
    public var limit: (
        min: LocalPriceLevel?,
        max: LocalPriceLevel?
    )
    public var storage: Bool

    @usableFromInline var supply: [Order]
    @usableFromInline var demand: [Order]

    @inlinable init(
        id: ID,
        stabilizationFund: Reservoir,
        stockpile: Reservoir,
        yesterday: Interval,
        today: Interval,
        limit: (
            min: LocalPriceLevel?,
            max: LocalPriceLevel?
        ),
        storage: Bool,
        supply: [Order],
        demand: [Order]
    ) {
        self.id = id
        self.stabilizationFund = stabilizationFund
        self.stockpile = stockpile
        self.yesterday = yesterday
        self.today = today
        self.limit = limit
        self.storage = storage
        self.supply = supply
        self.demand = demand
    }
}
extension LocalMarket {
    @inlinable init(id: ID) {
        let interval: Interval = .init(bid: .init(), ask: .init(), supply: 0, demand: 0)
        self.init(
            id: id,
            stabilizationFund: .zero,
            stockpile: .zero,
            yesterday: interval,
            today: interval,
            limit: (nil, nil),
            storage: false,
            supply: [],
            demand: []
        )
    }

    @inlinable public init(state: State) {
        self.init(
            id: state.id,
            stabilizationFund: state.stabilizationFund,
            stockpile: state.stockpile,
            yesterday: state.yesterday,
            today: state.today,
            limit: state.limit,
            storage: state.storage,
            supply: [],
            demand: []
        )
    }
    @inlinable public var state: State {
        .init(
            id: self.id,
            stabilizationFund: self.stabilizationFund,
            stockpile: self.stockpile,
            yesterday: self.yesterday,
            today: self.today,
            limit: self.limit,
            storage: self.storage
        )
    }
}
extension LocalMarket {
    @inlinable public var price: Candle<Double> {
        let y: Double = .init(self.yesterday.mid)
        let z: Double = .init(self.today.mid)
        return .init(
            o: y,
            l: min(y, z),
            h: max(y, z),
            c: z,
        )
    }

    @inlinable public var history: (yesterday: Interval, today: Interval)  {
        (self.yesterday, self.today)
    }
}
extension LocalMarket {
    public mutating func sell(amount: Int64, entity: LEI, memo: Order.Memo?) {
        // taker order goes on the bid side
        self.supply.append(.init(by: entity, type: .taker, memo: memo, size: amount))
        self.today.supply += amount
    }

    public mutating func buy(
        budget: Int64,
        entity: LEI,
        limit: Int64,
        memo: Order.Memo?,
    ) {
        guard let amount: Int64 = Self.quantity(
            budget: budget,
            limit: limit,
            price: self.today.ask
        ) else {
            return
        }

        // taker order goes on the ask side
        self.demand.append(.init(by: entity, type: .taker, memo: memo, size: amount))
        self.today.demand += amount
    }
}
extension LocalMarket {
    private static var minDefault: LocalPrice { .init(1 %/ 10_000) }
    private static var maxDefault: LocalPrice { .init(100_000_000 %/ 1) }

    private static func quantity(budget: Int64, limit: Int64, price: LocalPrice) -> Int64? {
        let quotient: Int64

        switch price.value.fraction {
        case (let n, denominator: let d?):
            quotient = budget <> (d %/ n)
        case (let n, denominator: nil):
            quotient = budget / n
        }

        if  quotient <= 0 {
            return nil
        }

        return min(quotient, limit)
    }
}
extension LocalMarket {
    public mutating func turn(template: Template) {
        self.yesterday = self.today
        self.limit = template.limit
        self.storage = template.storage

        let volume: Double = Double.init(self.today.mid) * Double.init(
            min(self.today.supply, self.today.demand)
        )
        let l: Double = Double.init(self.stabilizationFund.total) / (1 + 30 * volume)
        let s: Double = (1 + 99 * max(1 - l, 0)) / 10_000

        self.today = self.today.priceUpdate(
            spread: s,
            limit: (
                min: template.limit.min?.price ?? Self.minDefault,
                max: template.limit.max?.price ?? Self.maxDefault,
            )
        )

        self.stabilizationFund.turn()
        self.stockpile.turn()
    }

    public mutating func match(using random: inout PseudoRandom) -> (
        supply: [Order],
        demand: [Order]
    ) {
        var demandAvailable: Int64 = self.today.demand
        var supplyAvailable: Int64 = self.today.supply

        if  self.storage {
            if  self.today.supply < self.today.demand {
                let size: Int64 = min(
                    self.today.demand - self.today.supply,
                    self.stockpile.total
                )
                if  size > 0 {
                    // when selling, maker order goes on the ask side
                    let maker: Order = .init(
                        by: nil,
                        type: .maker,
                        memo: nil,
                        size: size
                    )
                    supplyAvailable += size
                    self.supply.append(maker)
                }
            } else {
                let limit: Int64 = (self.today.supply - self.today.demand) / 2
                if  limit > 0,
                    self.stabilizationFund.total > 0,
                    let size: Int64 = Self.quantity(
                        budget: self.stabilizationFund.total,
                        limit: limit,
                        price: self.today.bid
                    ) {
                    // when buying, maker order goes on the bid side
                    let maker: Order = .init(
                        by: nil,
                        type: .maker,
                        memo: nil,
                        size: size
                    )
                    demandAvailable += size
                    self.demand.append(maker)
                }
            }
        }

        if  supplyAvailable > demandAvailable {
            self.supply.shuffle(using: &random.generator)

            guard let matched: [Int64] = self.supply.distribute(
                demandAvailable,
                share: \.size
            ) else {
                // nonzero supply, but no asks?
                fatalError("unreachable")
            }

            for i: Int in self.supply.indices {
                self.supply[i].fill(.sell, price: self.today.prices, units: matched[i])
            }
            for i: Int in self.demand.indices {
                self.demand[i].fill(.buy, price: self.today.prices)
            }
        } else if supplyAvailable < demandAvailable {
            self.demand.shuffle(using: &random.generator)

            guard let matched: [Int64] = self.demand.distribute(
                supplyAvailable,
                share: \.size
            ) else {
                // nonzero demand, but no bids?
                fatalError("unreachable")
            }

            for i: Int in self.supply.indices {
                self.supply[i].fill(.sell, price: self.today.prices)
            }
            for i: Int in self.demand.indices {
                self.demand[i].fill(.buy, price: self.today.prices, units: matched[i])
            }
        } else {
            // supply and demand are evenly matched
            for i: Int in self.supply.indices {
                self.supply[i].fill(.sell, price: self.today.prices)
            }
            for i: Int in self.demand.indices {
                self.demand[i].fill(.buy, price: self.today.prices)
            }
        }

        // Reset for the next turn
        let supply: [Order] = self.supply
        let demand: [Order] = self.demand

        self.supply = []
        self.demand = []
        return (supply: supply, demand: demand)
    }
}
