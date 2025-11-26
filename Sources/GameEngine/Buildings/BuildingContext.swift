import Assert
import GameEconomy
import GameRules
import GameState
import GameIDs
import Random

struct BuildingContext: LegalEntityContext, RuntimeContext {
    let type: BuildingMetadata
    var state: Building

    private(set) var region: RegionalProperties?
    private(set) var equity: Equity<LEI>.Statistics

    private(set) var cashFlow: CashFlowStatement

    init(type: BuildingMetadata, state: Building) {
        self.type = type
        self.state = state

        self.region = nil
        self.equity = .init()
        self.cashFlow = .init()
    }
}
extension BuildingContext: Identifiable {
    var id: BuildingID { self.state.id }
}
extension BuildingContext {
    typealias ComputationPass = FactoryContext.ComputationPass
    private static var stockpileDays: ClosedRange<Int64> { 3 ... 7 }
}
extension BuildingContext {
    mutating func startIndexCount() {
    }
    mutating func addPosition(asset: LEI, value: Int64) {
        // TODO
    }
    mutating func update(equityStatistics: Equity<LEI>.Statistics) {
        self.equity = equityStatistics
    }

    mutating func afterIndexCount(
        world _: borrowing GameWorld,
        context: ComputationPass
    ) throws {
        self.region = context.planets[self.state.tile]?.properties

        self.cashFlow.reset()
        self.cashFlow.update(with: self.state.inventory.l)
        self.cashFlow.update(with: self.state.inventory.e)
    }
}
extension BuildingContext: TransactingContext {
    mutating func allocate(turn: inout Turn) {
        guard
        let country: CountryProperties = self.region?.occupiedBy else {
            return
        }

        self.state.z.ei = 1

        self.state.inventory.out.sync(with: self.type.output, releasing: 1)
        self.state.inventory.l.sync(
            with: self.type.maintenance,
            scalingFactor: (self.state.z.size, self.state.z.ei),
        )
        self.state.inventory.x.sync(
            with: self.type.development,
            scalingFactor: (self.state.z.size, self.state.z.ei),
        )

        if  self.equity.sharePrice.n > 0 {
            self.state.z.px = Double.init(self.equity.sharePrice)
        } else {
            self.state.z.px = 0
            self.state.equity = [:]
            self.equity = .init()
        }

        let weights: (
            segmented: SegmentedWeights<InelasticDemand>,
            tradeable: AggregateWeights
        ) = (
            segmented: .business(
                l: self.state.inventory.l,
                e: .empty,
                x: self.state.inventory.x,
                markets: turn.localMarkets,
                address: self.state.tile,
            ),
            tradeable: .business(
                l: self.state.inventory.l,
                e: .empty,
                x: self.state.inventory.x,
                markets: turn.worldMarkets,
                currency: country.currency.id,
            )
        )

        let budget: Building.Budget = .init(
            account: turn.bank[account: self.lei],
            state: self.state.z,
            weights: weights,
            stockpileMaxDays: Self.stockpileDays.upperBound,
            d: (l: 30, x: 365, v: max(0, self.state.z.profitability))
        )

        let sharesTarget: Int64 = self.state.z.size * self.type.sharesPerLevel + self.type.sharesInitial
        let sharesIssued: Int64 = max(0, sharesTarget - self.equity.shareCount)

        let sharesToIssue: Int64 = budget.buybacks == 0 ? sharesIssued : 0

        self.state.budget = budget

        // needs to be called even if quantity is zero, or the security will not
        // be tradeable today
        turn.stockMarkets.issueShares(
            currency: country.currency.id,
            quantity: sharesToIssue,
            security: self.security,
        )

        turn.localMarkets.tradeAsBusiness(
            selling: self.state.inventory.out.segmented,
            buying: weights.segmented,
            budget: (budget.l.segmented, 0, budget.x.segmented),
            as: self.lei,
            in: self.state.tile
        )
    }

    mutating func transact(turn: inout Turn) {
        guard
        let country: CountryProperties = self.region?.occupiedBy,
        let budget: Building.Budget = self.state.budget else {
            return
        }

        {
            let stockpileTarget: ResourceStockpileTarget = .random(
                in: Self.stockpileDays,
                using: &turn.random,
            )

            if  budget.l.tradeable > 0 {
                $0 += self.state.inventory.l.tradeAsBusiness(
                    stockpileDays: stockpileTarget,
                    spendingLimit: budget.l.tradeable,
                    in: country.currency.id,
                    on: &turn.worldMarkets,
                )
            }
            if  budget.x.tradeable > 0 {
                $0 += self.state.inventory.x.tradeAsBusiness(
                    stockpileDays: stockpileTarget,
                    spendingLimit: budget.x.tradeable,
                    in: country.currency.id,
                    on: &turn.worldMarkets,
                )
            }

            #assert(
                $0.balance >= 0,
                """
                Building (id = \(self.id), type = '\(self.type.symbol)') has negative cash! \
                (\($0))
                """
            )

            $0.r += self.state.inventory.out.sell(
                in: country.currency.id,
                on: &turn.worldMarkets
            )
        } (&turn.bank[account: self.lei])

        self.state.inventory.out.deposit(
            from: self.type.output,
            scalingFactor: (self.state.z.size, 1)
        )
        self.state.inventory.l.consume(
            from: self.type.maintenance,
            scalingFactor: (self.state.z.size, self.state.z.ei)
        )
        if  self.state.inventory.x.full {
            self.state.z.size += max(1, self.state.z.size / 256)
            self.state.inventory.x.consume(
                from: self.type.development,
                scalingFactor: (self.state.z.size, self.state.z.ei)
            )
        }

        self.state.z.fl = self.state.inventory.l.fulfilled
        self.state.z.fx = self.state.inventory.x.fulfilled

        self.state.spending.buybacks += turn.bank.buyback(
            security: self.security,
            budget: budget.buybacks,
            equity: &self.state.equity,
            random: &turn.random,
        )
        self.state.spending.dividend += turn.bank.transfer(
            budget: budget.dividend,
            source: self.lei,
            recipients: self.state.equity.shares.values.shuffled(
                using: &turn.random.generator
            )
        )

        let profit: ProfitMargins = self.state.profit
        self.state.z.mix(profitability: profit.operatingProfitability)
    }

    mutating func advance(turn: inout Turn) {
        if  self.state.z.fl < 1, self.state.z.size > 1 {
            let attrition: Double = 0.01 * (1 - self.state.z.fl)
            self.state.z.size -= Binomial[self.state.z.size - 1, attrition].sample(
                using: &turn.random.generator
            )
        }

        self.state.z.vl = self.state.inventory.l.valueAcquired
        self.state.z.vx = self.state.inventory.x.valueAcquired

        guard
        let country: CountryProperties = self.region?.occupiedBy else {
            return
        }

        self.state.equity.split(
            price: self.state.z.px,
            turn: &turn,
            notifying: [country.id]
        )
    }
}
