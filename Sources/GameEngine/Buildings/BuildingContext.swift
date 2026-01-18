import Assert
import GameEconomy
import GameRules
import GameState
import GameIDs
import Random

struct BuildingContext: RuntimeContext {
    let type: BuildingMetadata
    var state: Building
    private(set) var stats: Building.Stats

    private(set) var region: RegionalProperties?
    private(set) var equity: Equity<LEI>.Statistics

    init(type: BuildingMetadata, state: Building) {
        self.type = type
        self.state = state
        self.stats = .init()

        self.region = nil
        self.equity = .init()
    }
}
extension BuildingContext: Identifiable {
    var id: BuildingID { self.state.id }
}
extension BuildingContext: LegalEntityContext {
    static var stockpileDaysRange: ClosedRange<Int64> { 4 ... 8 }
}
extension BuildingContext {
    typealias ComputationPass = FactoryContext.ComputationPass
    private static var utilizationThreshold: Double { 0.99 }

    var snapshot: BuildingSnapshot? {
        guard let region: RegionalProperties = self.region else {
            return nil
        }
        return .init(
            metadata: self.type,
            stats: self.stats,
            region: region,
            equity: self.equity,
            state: self.state,
        )
    }
}
extension BuildingContext {
    mutating func startIndexCount() {
        self.stats.startIndexCount(self.state)
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
        self.region = context.tiles[self.state.tile]?.properties
    }
}
extension BuildingContext: TransactingContext {
    mutating func allocate(turn: inout Turn) {
        guard
        let region: RegionalProperties = self.region else {
            return
        }

        let π: Double = self.stats.financial.profit.π
        self.state.z.mix(profitability: π)

        if  let units: Int64 = self.state.backgroundable(
                base: min(self.stats.utilization - Self.utilizationThreshold, π),
                random: &turn.random
            ) {
            self.state.z.background(active: units)
            self.state.mothballed += units
        } else if
            let restoration: Double = self.state.restoration,
            self.state.z.vacant > 0,
            self.stats.utilization > Self.utilizationThreshold {
            let scale: Double = 1 / (1 - Self.utilizationThreshold) * (
                self.stats.utilization - Self.utilizationThreshold
            )
            let restored: Int64 = Binomial[self.state.z.vacant, restoration * scale].sample(
                using: &turn.random.generator
            )
            self.state.z.restore(vacant: restored)
            self.state.restored += restored
        }

        self.state.z.ei = 1

        self.state.inventory.l.sync(
            with: self.type.operations,
            scalingFactor: (self.state.z.active, self.state.z.ei),
        )
        self.state.inventory.e.sync(
            with: self.type.maintenance,
            scalingFactor: (self.state.z.total, self.state.z.ei),
        )
        self.state.inventory.x.sync(
            with: self.type.development,
            scalingFactor: (self.state.z.total, self.state.z.ei),
        )

        self.state.inventory.out.sync(with: self.type.output)
        self.state.inventory.out.produce(
            from: self.type.output,
            scalingFactor: (self.state.z.active, 1)
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
            tradeable: AggregateWeights<InelasticDemand>
        ) = (
            segmented: .business(
                l: self.state.inventory.l,
                e: self.state.inventory.e,
                x: self.state.inventory.x,
                markets: turn.localMarkets,
                address: self.state.tile,
            ),
            tradeable: .business(
                l: self.state.inventory.l,
                e: self.state.inventory.e,
                x: self.state.inventory.x,
                markets: turn.worldMarkets,
                currency: region.currency.id,
            )
        )

        let budget: Building.Budget = .init(
            account: turn.bank[account: self.lei],
            weights: weights,
            state: self.state.z,
            stockpileMaxDays: Self.stockpileDaysMax,
            invest: self.state.developmentRate(utilization: self.stats.utilization)
        )

        let sharesTarget: Int64 = self.state.z.total * self.type.sharesPerLevel + self.type.sharesInitial
        let sharesIssued: Int64 = max(0, sharesTarget - self.equity.shareCount)

        let sharesToIssue: Int64 = budget.buybacks == 0 ? sharesIssued : 0

        self.state.budget = budget

        // needs to be called even if quantity is zero, or the security will not
        // be tradeable today
        turn.stockMarkets.issueShares(
            currency: region.currency.id,
            quantity: sharesToIssue,
            security: self.security,
        )

        turn.localMarkets.tradeAsBusiness(
            selling: self.state.inventory.out.segmented,
            buying: weights.segmented,
            budget: (budget.l.segmented, budget.e.segmented, budget.x.segmented),
            as: self.lei,
            in: self.state.tile
        )
    }

    mutating func transact(turn: inout Turn) {
        guard
        let region: RegionalProperties = self.region,
        let budget: Building.Budget = self.state.budget else {
            return
        }

        {
            let stockpileDays: ResourceStockpileTarget = Self.stockpileTarget(&turn.random)

            if  budget.l.tradeable > 0 {
                $0 += self.state.inventory.l.tradeAsBusiness(
                    stockpileDays: stockpileDays,
                    spendingLimit: budget.l.tradeable,
                    in: region.currency.id,
                    on: &turn.worldMarkets,
                )
            }
            if  budget.e.tradeable > 0 {
                $0 += self.state.inventory.e.tradeAsBusiness(
                    stockpileDays: stockpileDays,
                    spendingLimit: budget.e.tradeable,
                    in: region.currency.id,
                    on: &turn.worldMarkets,
                )
            }
            if  budget.x.tradeable > 0 {
                $0 += self.state.inventory.x.tradeAsBusiness(
                    stockpileDays: stockpileDays,
                    spendingLimit: budget.x.tradeable,
                    in: region.currency.id,
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

            if !self.state.inventory.out.tradeable.isEmpty {
                $0.r += budget.liquidate ? self.state.inventory.out.sell(
                    in: region.currency.id,
                    to: &turn.worldMarkets,
                ) : self.state.inventory.out.sell(
                    in: region.currency.id,
                    to: &turn.worldMarkets,
                    random: &turn.random
                )
            }
        } (&turn.bank[account: self.lei])

        self.state.z.fl = self.state.inventory.l.consumeAmortized(
            from: self.type.operations,
            scalingFactor: (self.state.z.active, self.state.z.ei)
        )
        self.state.z.fe = self.state.inventory.e.consumeAmortized(
            from: self.type.maintenance,
            scalingFactor: (self.state.z.total, self.state.z.ei)
        )

        let growth: Bool

        (self.state.z.fx, growth) = self.state.inventory.x.consumeAvailable(
            from: self.type.development,
            scalingFactor: (self.state.z.total, self.state.z.ei)
        )

        if  growth {
            // in this situation, `active` is usually close to or equal to `total`
            let created: Int64 = max(1, self.state.z.total / 256)
            self.state.created += created
            self.state.z.active += created
        }

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
    }

    mutating func advance(turn: inout Turn) {
        if  let attrition: Double = self.state.attrition {
            if  self.state.z.vacant > 0 {
                let destroyed: Int64 = Binomial[self.state.z.vacant, attrition].sample(
                    using: &turn.random.generator
                )
                self.state.z.vacant -= destroyed
                self.state.destroyed += destroyed
            }
        }

        self.state.z.vl = self.state.inventory.l.valueAcquired
        self.state.z.ve = self.state.inventory.e.valueAcquired
        self.state.z.vx = self.state.inventory.x.valueAcquired
        self.state.z.vout = self.state.inventory.out.valueEstimate

        guard
        let country: CountryID = self.region?.occupiedBy else {
            return
        }

        self.state.equity.split(at: self.state.z.px, in: country, turn: &turn)
    }
}
