import Assert
import D
import Fraction
import GameIDs
import Random

@frozen public struct LocalMarket: Identifiable {
    public let id: ID
    /// Change to stabilization fund this turn, excluding changes from stockpile trades.
    public var stabilizationFundFees: Int64
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
        stabilizationFundFees: Int64,
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
        self.stabilizationFundFees = stabilizationFundFees
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
            stabilizationFundFees: 0,
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
            stabilizationFundFees: state.stabilizationFundFees,
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
            stabilizationFundFees: self.stabilizationFundFees,
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
    public mutating func sell(amount: Int64, entity: LEI, memo: Memo?) {
        // taker order goes on the bid side
        self.supply.append(.init(by: entity, type: .taker, memo: memo, size: amount))
        self.today.supply += amount
    }

    public mutating func buy(
        budget: Int64,
        entity: LEI,
        limit: Int64,
        memo: Memo?,
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

        let spread: Double?
        if  template.storage {
            let volume: Double = Double.init(self.today.mid) * Double.init(
                min(self.today.supply, self.today.demand)
            )
            let l: Double = Double.init(self.stabilizationFund.total) / (1 + 30 * volume)
            spread = (1 + 149 * max(1 - l, 0)) / 10_000
        } else {
            spread = nil
        }

        self.today.update(
            spread: spread,
            limit: (
                min: template.limit.min?.price ?? Self.minDefault,
                max: template.limit.max?.price ?? Self.maxDefault,
            )
        )

        self.limit = template.limit
        self.storage = template.storage

        self.stabilizationFund.turn()
        self.stockpile.turn()
    }

    @inlinable public mutating func match(
        random: inout PseudoRandom,
        report: (Fill, Side) -> (),
    ) {
        let matched: (
            supply: [LocalMarket.Order],
            demand: [LocalMarket.Order]
        ) = self.match(using: &random)

        var proceeds: Int64 = 0
        var cashFlow: Int64 = 0

        for order: LocalMarket.Order in matched.supply {
            #assert(order.unitsMatched <= order.size, "Order overfilled! (\(order))")

            guard let entity: LEI = order.by else {
                // when we sell from the stockpile,
                // we receive proceeds for the stabilization fund
                proceeds += order.valueMatched
                self.stockpile -= order.unitsMatched
                continue
            }

            cashFlow -= order.valueMatched

            let fill: Fill = .init(
                entity: entity,
                filled: order.unitsMatched,
                value: order.valueMatched,
                memo: order.memo
            )

            report(fill, .sell)
        }
        for order: LocalMarket.Order in matched.demand {
            #assert(order.unitsMatched <= order.size, "Order overfilled! (\(order))")

            guard let entity: LEI = order.by else {
                // when we buy for the stockpile,
                // we spend proceeds from the stabilization fund
                proceeds -= order.valueMatched
                self.stockpile += order.unitsMatched
                continue
            }

            cashFlow += order.valueMatched

            let fill: Fill = .init(
                entity: entity,
                filled: order.unitsMatched,
                value: order.valueMatched,
                memo: order.memo
            )

            report(fill, .buy)
        }

        self.stabilizationFundFees = cashFlow - proceeds
        #assert(
            self.stabilizationFundFees >= 0,
            "LocalMarket \(self.id) collected negative (\(self.stabilizationFundFees)) fees!!!"
        )

        self.stabilizationFund += cashFlow
        #assert(
            self.stabilizationFund.total >= 0,
            "LocalMarket \(self.id) has negative stabilization fund!!!"
        )
    }
    @usableFromInline mutating func match(using random: inout PseudoRandom) -> (
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
