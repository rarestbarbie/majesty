import Assert
import D
import Fraction
import GameConditions
import GameEconomy
import GameIDs
import GameRules
import GameState
import Random

struct PopContext: RuntimeContext {
    let type: PopMetadata
    var state: Pop
    private(set) var stats: Pop.Stats
    private(set) var region: RegionalProperties?
    private(set) var equity: Equity<LEI>.Statistics
    private(set) var mines: [MineID: MiningJobConditions]

    private var miningJobRank: [MineID: Int]
    private var factoryJobPay: [FactoryID: Int64]

    public init(type: PopMetadata, state: Pop) {
        self.type = type
        self.state = state
        self.stats = .init()
        self.region = nil
        self.equity = .init()
        self.mines = [:]
        self.miningJobRank = [:]
        self.factoryJobPay = [:]
    }
}
extension PopContext: Identifiable {
    var id: PopID { self.state.id }
}
extension PopContext: LegalEntityContext {
    static var stockpileDaysRange: ClosedRange<Int64> { 4 ... 8 }
}
extension PopContext {
    var snapshot: PopSnapshot? {
        guard let region: RegionalProperties = self.region else {
            return nil
        }
        return .init(
            metadata: self.type,
            stats: self.stats,
            region: region,
            equity: self.equity,
            mines: self.mines,
            state: state,
        )
    }
}
extension PopContext {
    mutating func startIndexCount() {
        self.stats.startIndexCount(self.state)
    }

    mutating func addPosition(asset: LEI, value: Int64) {
        guard value > 0 else {
            return
        }

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

        self.mines.removeAll(keepingCapacity: true)
        for job: MiningJob in self.state.mines.values {
            let (state, type): (Mine, MineMetadata) = try context.mines[job.id]
            self.mines[job.id] = .init(
                type: state.type,
                output: type.base,
                factor: state.y.efficiency
            )
        }

        self.factoryJobPay = [:]
        self.miningJobRank = [:]

        if  case .Miner = self.state.type.occupation {
            // mining yield does not affect Politicians
            for job: MineID in self.state.mines.keys {
                self.miningJobRank[job] = context.mines[job]?.z.yieldRank
            }
        } else if case .Clerk = self.state.type.stratum {
            for job: FactoryID in self.state.factories.keys {
                self.factoryJobPay[job] = context.factories[job]?.z.cn
            }
        } else {
            for job: FactoryID in self.state.factories.keys {
                self.factoryJobPay[job] = context.factories[job]?.z.wn
            }
        }
    }
}
extension PopContext {
    var l: ResourceTier {
        self.type.l
    }
    var e: ResourceTier {
        self.type.e
    }
    var x: ResourceTier {
        self.type.x
    }
    var output: ResourceTier {
        self.type.output
    }
}
extension PopContext: AllocatingContext {
    mutating func allocate(turn: inout Turn) {
        guard let region: RegionalProperties = self.region else {
            return
        }

        if case .Ward = self.state.type.stratum {
            let π: Double = self.stats.financial.profit.π
            self.state.z.mix(profitability: π)

            if  let units: Int64 = self.state.backgroundable(base: π, random: &turn.random) {
                self.state.z.background(active: units)
                self.state.mothballed += units
            } else if
                let restoration: Double = self.state.restoration,
                self.state.z.vacant > 0 {
                let restored: Int64 = Binomial[self.state.z.vacant, restoration].sample(
                    using: &turn.random.generator
                )
                self.state.z.restore(vacant: restored)
                self.state.restored += restored
            }
        }

        let currency: CurrencyID = region.currency.id

        self.state.inventory.out.sync(with: self.output)
        self.state.inventory.out.produce(
            from: self.output,
            scalingFactor: (self.state.z.active, 1)
        )
        for j: Int in self.state.mines.values.indices {
            {
                guard
                let conditions: MiningJobConditions = self.mines[$0.id] else {
                    fatalError("missing stored info for mine '\($0.id)'!!!")
                }

                $0.out.sync(with: conditions.output)
                $0.out.produce(
                    from: conditions.output,
                    scalingFactor: ($0.count, conditions.factor)
                )
            } (&self.state.mines.values[j])
        }

        /// Compute vertical weights.
        let z: (l: Double, e: Double, x: Double) = self.state.needsScalePerCapita
        self.state.inventory.l.sync(
            with: self.l,
            scalingFactor: (self.state.z.active, z.l),
        )
        self.state.inventory.e.sync(
            with: self.e,
            scalingFactor: (self.state.z.total, z.e),
        )
        self.state.inventory.x.sync(
            with: self.x,
            scalingFactor: (self.state.z.active, z.x),
        )

        let budget: Pop.Budget

        if  case .Ward = self.state.type.stratum {
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
                    currency: currency
                )
            )

            budget = .slave(
                account: turn.bank[account: self.id],
                weights: weights,
                state: self.state.z,
                stockpileMaxDays: Self.stockpileDaysMax,
            )

            // Align share price
            self.state.z.px = Double.init(self.equity.sharePrice)
            turn.stockMarkets.issueShares(
                currency: currency,
                quantity: max(0, self.state.z.total - self.equity.shareCount),
                security: self.security,
            )

            turn.localMarkets.tradeAsBusiness(
                selling: self.state.inventory.out.segmented,
                buying: weights.segmented,
                budget: (
                    budget.l.segmented,
                    budget.e.segmented,
                    budget.x.segmented,
                ),
                as: self.lei,
                in: self.state.tile,
            )
        } else {
            let weights: (
                segmented: SegmentedWeights<ElasticDemand>,
                tradeable: AggregateWeights<ElasticDemand>
            ) = (
                segmented: .consumer(
                    l: self.state.inventory.l,
                    e: self.state.inventory.e,
                    x: self.state.inventory.x,
                    markets: turn.localMarkets,
                    address: self.state.tile,
                ),
                tradeable: .consumer(
                    l: self.state.inventory.l,
                    e: self.state.inventory.e,
                    x: self.state.inventory.x,
                    markets: turn.worldMarkets,
                    currency: currency
                )
            )

            budget = .free(
                account: turn.bank[account: self.id],
                weights: weights,
                state: self.state.z,
                stockpileMaxDays: Self.stockpileDaysMax,
                investor: self.state.type.stratum == .Owner
            )

            // this short-circuits internally if investment is zero
            turn.stockMarkets.queueRandomPurchase(
                buyer: .pop(self.state.id),
                value: budget.investment,
                currency: currency
            )
            turn.localMarkets.tradeAsConsumer(
                selling: self.state.inventory.out.segmented,
                buying: weights.segmented,
                budget: (
                    budget.l.segmented,
                    budget.e.segmented,
                    budget.x.segmented,
                ),
                as: self.lei,
                in: self.state.tile,
            )
            for job: MiningJob in self.state.mines.values {
                turn.localMarkets.sell(
                    supply: job.out.segmented,
                    entity: self.lei,
                    memo: .mine(job.id),
                    tile: self.state.tile,
                )
            }
        }

        self.state.budget = budget
    }
}
extension PopContext: TransactingContext {
    mutating func transact(turn: inout Turn) {
        let enslaved: Bool = self.state.type.stratum == .Ward

        guard
        let region: RegionalProperties = self.region,
        let budget: Pop.Budget = self.state.budget else {
            return
        }

        {
            (account: inout Bank.Account) in

            if !self.state.inventory.out.tradeable.isEmpty ||
               !self.state.mines.isEmpty {
                // there are a lot more pops than there are factories, so to reduce the number
                // of market trades, we sell stockpiles entirely or not at all, at random.
                if  budget.liquidate || turn.random.wait(
                        // this should be in sync for all the mining job outputs as well
                        1 + self.state.inventory.out.tradeableDaysReserve,
                        1 ... Self.stockpileDaysRange.upperBound
                    ) {
                    account.r += self.state.inventory.out.sell(
                        in: region.currency.id,
                        to: &turn.worldMarkets
                    )
                    for j: Int in self.state.mines.values.indices {
                        account.r += self.state.mines.values[j].out.sell(
                            in: region.currency.id,
                            to: &turn.worldMarkets
                        )
                    }
                } else {
                    self.state.inventory.out.mark(
                        in: region.currency.id,
                        to: turn.worldMarkets
                    )
                    for j: Int in self.state.mines.values.indices {
                        self.state.mines.values[j].out.mark(
                            in: region.currency.id,
                            to: turn.worldMarkets
                        )
                    }
                }
            }

            let stockpileDays: ResourceStockpileTarget = Self.stockpileTarget(&turn.random)
            let z: (l: Double, e: Double, x: Double) = self.state.needsScalePerCapita

            if  budget.l.tradeable > 0 {
                account += enslaved ? self.state.inventory.l.tradeAsBusiness(
                    stockpileDays: stockpileDays,
                    spendingLimit: budget.l.tradeable,
                    in: region.currency.id,
                    on: &turn.worldMarkets,
                ) : self.state.inventory.l.tradeAsConsumer(
                    stockpileDays: stockpileDays,
                    spendingLimit: budget.l.tradeable,
                    in: region.currency.id,
                    on: &turn.worldMarkets,
                )
            }

            self.state.z.fl = self.state.inventory.l.consumeAmortized(
                from: self.l,
                scalingFactor: (self.state.z.active, z.l)
            )

            if  budget.e.tradeable > 0 {
                account += enslaved ? self.state.inventory.e.tradeAsBusiness(
                    stockpileDays: stockpileDays,
                    spendingLimit: budget.e.tradeable,
                    in: region.currency.id,
                    on: &turn.worldMarkets,
                ) : self.state.inventory.e.tradeAsConsumer(
                    stockpileDays: stockpileDays,
                    spendingLimit: budget.e.tradeable,
                    in: region.currency.id,
                    on: &turn.worldMarkets,
                )
            }

            self.state.z.fe = self.state.inventory.e.consumeAmortized(
                from: self.e,
                scalingFactor: (self.state.z.total, z.e)
            )

            if  enslaved {
                self.state.z.fx = 0
                return
            }

            if  budget.x.tradeable > 0 {
                account += self.state.inventory.x.tradeAsConsumer(
                    stockpileDays: stockpileDays,
                    spendingLimit: budget.x.tradeable,
                    in: region.currency.id,
                    on: &turn.worldMarkets,
                )
            }

            self.state.z.fx = self.state.inventory.x.consumeAmortized(
                from: self.x,
                scalingFactor: (self.state.z.active, z.x)
            )

            // Welfare
            account.s += self.state.z.active * region.minwage / 10
        } (&turn.bank[account: self.id])

        if  enslaved {
            // Pay dividends to shareholders, if any.
            self.state.spending.dividend += turn.bank.transfer(
                budget: budget.dividend,
                source: self.lei,
                recipients: self.state.equity.shares.values.shuffled(
                    using: &turn.random.generator
                )
            )
            self.state.spending.buybacks += turn.bank.buyback(
                security: self.security,
                budget: budget.buybacks,
                equity: &self.state.equity,
                random: &turn.random,
            )
        }
    }
}
extension PopContext {
    static var slaveBreedingBase: Decimal { 1‰ }
    static var slaveCullingBase: Decimal { 1‰ }

    static func mil(fl: Double) -> Double { 0.010 * (1.0 - fl) }
    static func mil(fe: Double) -> Double { 0.004 * (0.5 - fe) }
    static func mil(fx: Double) -> Double { 0.004 * (0.0 - fx) }

    static func con(fl: Double) -> Double { 0.010 * (fl - 1.0) }
    static func con(fe: Double) -> Double { 0.002 * (1.0 - fe) }
    static func con(fx: Double) -> Double { 0.020 * (fx - 0.0) }
}
extension PopContext {
    mutating func advance(turn: inout Turn) {
        self.state.z.vl = self.state.inventory.l.valueAcquired
        self.state.z.ve = self.state.inventory.e.valueAcquired
        self.state.z.vx = self.state.inventory.x.valueAcquired

        guard
        let region: RegionalProperties = self.region else {
            return
        }

        self.state.z.mil += Self.mil(fl: self.state.z.fl)
        self.state.z.mil += Self.mil(fe: self.state.z.fe)
        self.state.z.mil += Self.mil(fx: self.state.z.fx)

        self.state.z.con += Self.con(fl: self.state.z.fl)
        self.state.z.con += Self.con(fe: self.state.z.fe)
        self.state.z.con += Self.con(fx: self.state.z.fx)

        self.state.z.mil = max(0, min(10, self.state.z.mil))
        self.state.z.con = max(0, min(10, self.state.z.con))

        if case .Ward = self.state.type.stratum {
            if  let attrition: Double = self.state.attrition {
                if  self.state.z.vacant > 0 {
                    let r: Decimal = Self.slaveCullingBase
                        + region.modifiers.livestockCullingEfficiency.value
                    let p: Double = Double.init(r) * attrition
                    let destroyed: Int64 = Binomial[self.state.z.vacant, p].sample(
                        using: &turn.random.generator
                    )
                    self.state.z.vacant -= destroyed
                    self.state.destroyed += destroyed
                }
            } else {
                let developmentRate: Double = self.state.developmentRate(utilization: 1)
                if  developmentRate > 0 {
                    let r: Decimal = Self.slaveBreedingBase
                        + region.modifiers.livestockBreedingEfficiency.value
                    let p: Double = Double.init(r) * developmentRate
                    // all slaves, including backgrounded ones, can breed
                    let birthed: Int64 = Binomial[self.state.z.total, p].sample(
                        using: &turn.random.generator
                    ) + Int64.random(
                        in: 0 ... Int64.init((4 * developmentRate).rounded()),
                        using: &turn.random.generator
                    )

                    self.state.z.active += birthed
                    self.state.created += birthed
                }
            }

            self.state.equity.split(at: self.state.z.px, in: region.occupiedBy, turn: &turn)
        } else {
            self.convert(turn: &turn)
        }

        // We do not need to remove jobs that have no employees left, that will be done
        // automatically by ``Pop.turn``.
        let factoryJobs: Range<Int> = self.state.factories.values.indices
        let miningJobs: Range<Int> = self.state.mines.values.indices

        let w0: Double = .init(region.minwage)
        let q: Double = 0.002
        for i: Int in factoryJobs {
            {
                /// At this rate, if the factory pays minimum wage or less, about half of
                /// non-union workers, and one third of union workers, will quit every year.
                $0.quit(
                    rate: q * w0 / max(w0, self.factoryJobPay[$0.id].map(Double.init(_:)) ?? 1),
                    using: &turn.random.generator
                )
            } (&self.state.factories.values[i])
        }
        for i: Int in miningJobs {
            {
                $0.quit(
                    rate: q + q * (self.miningJobRank[$0.id].map(Double.init(_:)) ?? 2),
                    using: &turn.random.generator
                )
            } (&self.state.mines.values[i])
        }

        let unemployed: Int64 = self.state.z.active - self.state.employed()
        if  unemployed < 0 {
            /// We have negative unemployment! This happens when the popuation shrinks, either
            /// through pop death or conversion.
            var nonexistent: Int64 = -unemployed
            /// This algorithm will probably generate more indices than we need. Alternatively,
            /// we could draw indices on demand, but that would have very pathological
            /// performance in the rare case that we have many empty jobs that have not yet
            /// been linted.
            for i: Int in factoryJobs.shuffled(using: &turn.random.generator) {
                guard 0 < nonexistent else {
                    break
                }

                self.state.factories.values[i].remove(excess: &nonexistent)
            }
            for i: Int in miningJobs.shuffled(using: &turn.random.generator) {
                guard 0 < nonexistent else {
                    break
                }

                self.state.mines.values[i].remove(excess: &nonexistent)
            }
        }
    }
}
extension PopContext {
    private mutating func convert(turn: inout Turn) {
        let promotion: ConditionEvaluator
        let demotion: ConditionEvaluator
        let tile: Address

        if  let region: RegionalProperties = self.region {
            let converter: Converter  = .init(
                region: region,
                stats: self.stats,
                type: self.state.type,
                y: self.state.y,
                z: self.state.z
            )

            promotion = converter.promotion
            demotion = converter.demotion
            tile = region.id
        } else {
            fatalError("missing region for pop '\(self.state.id)'!!!")
        }

        let current: PopOccupation = self.state.occupation

        // when demoting, inherit 1 percent
        let ledger: EconomicLedger = turn.ledger.z.economy
        self.state.egress(
            evaluator: demotion,
            inherit: 1 %/ 100,
            on: &turn,
        ) {
            current.demotes(to: $0)
                ? 0.01 + 0.4 * (ledger.employment[tile / $0]?.employment ?? 0)
                : 0
        }

        // when promoting, inherit all
        self.state.egress(
            evaluator: promotion,
            inherit: nil,
            on: &turn,
        ) {
            current.promotes(to: $0) ? 1 : 0
        }
    }
}
