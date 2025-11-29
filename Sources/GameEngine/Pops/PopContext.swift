import Assert
import D
import Fraction
import GameConditions
import GameEconomy
import GameIDs
import GameRules
import GameState
import GameUI
import Random

struct PopContext: RuntimeContext, LegalEntityContext {
    let type: PopMetadata
    var state: Pop
    private(set) var stats: Pop.Stats
    private(set) var livestock: CultureMetadata?
    private(set) var region: RegionalAuthority?
    private(set) var equity: Equity<LEI>.Statistics
    private(set) var mines: [MineID: MiningJobConditions]

    private var miningJobRank: [MineID: Int]
    private var factoryJobPay: [FactoryID: Int64]

    public init(type: PopMetadata, state: Pop) {
        self.type = type
        self.state = state
        self.stats = .init()
        self.livestock = nil
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
extension PopContext {
    private static var stockpileDays: ClosedRange<Int64> { 3 ... 7 }

    mutating func startIndexCount() {
        // computed during indexing, because the index pass uses it
        self.stats.update(from: self.state)
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
}
extension PopContext {
    mutating func afterIndexCount(
        world _: borrowing GameWorld,
        context: ComputationPass
    ) throws {
        self.region = context.planets[self.state.tile]?.authority

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

        if  case .Livestock = self.state.type {
            self.livestock = context.cultures[self.state.race]?.type
        } else if
            case .Miner = self.state.type {
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
        self.livestock?.diet ?? self.type.l
    }
    var e: ResourceTier {
        self.type.e
    }
    var x: ResourceTier {
        self.type.x
    }
    var output: ResourceTier {
        self.livestock?.meat ?? self.type.output
    }
}
extension PopContext: AllocatingContext {
    mutating func allocate(turn: inout Turn) {
        guard let region: RegionalProperties = self.region?.properties else {
            return
        }

        if  case _? = self.livestock {
            let employmentThreshold: Double = 0.95
            if  self.stats.employmentBeforeEgress < employmentThreshold || self.state.y.fl < 1 {
                let cullable: Int64 = self.state.z.size - 1
                if  cullable > 0 {
                    /// a number between -1 and 0
                    let share: Double = min(
                        self.stats.employmentBeforeEgress - employmentThreshold,
                        self.state.y.fl - 1
                    )
                    let r: Decimal = 1‰ + region.modifiers.livestockCullingEfficiency.value
                    let p: Double = -Double.init(r) * share
                    self.state.z.size -= Binomial[cullable, p].sample(
                        using: &turn.random.generator
                    )
                }
            } else if self.state.z.profitability > 0 {
                let r: Decimal = 1‰ + region.modifiers.livestockBreedingEfficiency.value
                let p: Double = Double.init(r) * self.state.z.profitability
                self.state.z.size += Binomial[self.state.z.size, p].sample(
                    using: &turn.random.generator
                ) + Int64.random(
                    in: 0 ... Int64.init((4 * self.state.z.profitability).rounded()),
                    using: &turn.random.generator
                )
            }
        }

        let currency: CurrencyID = region.currency.id

        self.state.inventory.out.sync(with: self.output, releasing: 1)
        for j: Int in self.state.mines.values.indices {
            {
                guard
                let output: ResourceTier = self.mines[$0.id]?.output else {
                    fatalError("missing stored info for mine '\($0.id)'!!!")
                }

                $0.out.sync(with: output, releasing: 1 %/ 4)
            } (&self.state.mines.values[j])
        }

        /// Compute vertical weights.
        let z: (l: Double, e: Double, x: Double) = self.state.needsScalePerCapita
        self.state.inventory.l.sync(
            with: self.l,
            scalingFactor: (self.state.z.size, z.l),
        )
        self.state.inventory.e.sync(
            with: self.e,
            scalingFactor: (self.state.z.size, z.e),
        )
        self.state.inventory.x.sync(
            with: self.x,
            scalingFactor: (self.state.z.size, z.x),
        )

        let budget: Pop.Budget

        if case .Ward = self.state.type.stratum {
            let weights: (
                segmented: SegmentedWeights<InelasticDemand>,
                tradeable: AggregateWeights
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
                account: turn.bank[account: self.lei],
                weights: weights,
                state: self.state.z,
                stockpileMaxDays: Self.stockpileDays.upperBound,
            )

            // Align share price
            self.state.z.px = Double.init(self.equity.sharePrice)
            turn.stockMarkets.issueShares(
                currency: currency,
                quantity: max(0, self.state.z.size - self.equity.shareCount),
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
                tradeable: AggregateWeights
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
                account: turn.bank[account: self.lei],
                weights: weights,
                state: self.state.z,
                stockpileMaxDays: Self.stockpileDays.upperBound,
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
        let region: RegionalProperties = self.region?.properties,
        let budget: Pop.Budget = self.state.budget else {
            return
        }

        {
            (account: inout Bank.Account) in

            account.r += self.state.inventory.out.sell(
                in: region.currency.id,
                on: &turn.worldMarkets
            )
            self.state.inventory.out.deposit(
                from: self.output,
                scalingFactor: (self.state.z.size, 1)
            )

            for j: Int in self.state.mines.values.indices {
                account.r += {
                    guard
                    let conditions: MiningJobConditions = self.mines[$0.id] else {
                        fatalError("missing stored info for mine '\($0.id)'!!!")
                    }

                    $0.out.deposit(
                        from: conditions.output,
                        scalingFactor: ($0.count, conditions.factor)
                    )
                    return $0.out.sell(in: region.currency.id, on: &turn.worldMarkets)
                } (&self.state.mines.values[j])
            }

            let target: ResourceStockpileTarget = .random(
                in: Self.stockpileDays,
                using: &turn.random
            )
            let z: (l: Double, e: Double, x: Double) = self.state.needsScalePerCapita

            if  budget.l.tradeable > 0 {
                account += enslaved ? self.state.inventory.l.tradeAsBusiness(
                    stockpileDays: target,
                    spendingLimit: budget.l.tradeable,
                    in: region.currency.id,
                    on: &turn.worldMarkets,
                ) : self.state.inventory.l.tradeAsConsumer(
                    stockpileDays: target,
                    spendingLimit: budget.l.tradeable,
                    in: region.currency.id,
                    on: &turn.worldMarkets,
                )
            }

            self.state.z.fl = self.state.inventory.l.fulfilled
            self.state.inventory.l.consume(
                from: self.l,
                scalingFactor: (self.state.z.size, z.l)
            )

            if  enslaved {
                self.state.z.fe = 1
                self.state.z.fx = 0
                return
            }

            if  budget.e.tradeable > 0 {
                account += self.state.inventory.e.tradeAsConsumer(
                    stockpileDays: target,
                    spendingLimit: budget.e.tradeable,
                    in: region.currency.id,
                    on: &turn.worldMarkets,
                )
            }

            self.state.z.fe = self.state.inventory.e.fulfilled
            self.state.inventory.e.consume(
                from: self.e,
                scalingFactor: (self.state.z.size, z.e)
            )

            if  budget.x.tradeable > 0 {
                account += self.state.inventory.x.tradeAsConsumer(
                    stockpileDays: target,
                    spendingLimit: budget.x.tradeable,
                    in: region.currency.id,
                    on: &turn.worldMarkets,
                )
            }

            self.state.z.fx = self.state.inventory.x.fulfilled
            self.state.inventory.x.consume(
                from: self.x,
                scalingFactor: (self.state.z.size, z.x)
            )

            // Welfare
            account.s += self.state.z.size * region.minwage / 10
        } (&turn.bank[account: self.lei])

        if  enslaved {
            self.state.z.mix(profitability: self.state.profit.marginalProfitability)

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
    private static func mil(fl: Double) -> Double { 0.010 * (1.0 - fl) }
    private static func mil(fe: Double) -> Double { 0.004 * (0.5 - fe) }
    private static func mil(fx: Double) -> Double { 0.004 * (0.0 - fx) }

    private static func con(fl: Double) -> Double { 0.010 * (fl - 1.0) }
    private static func con(fe: Double) -> Double { 0.002 * (1.0 - fe) }
    private static func con(fx: Double) -> Double { 0.020 * (fx - 0.0) }
}
extension PopContext {
    mutating func advance(turn: inout Turn) {
        self.state.z.vl = self.state.inventory.l.valueAcquired
        self.state.z.ve = self.state.inventory.e.valueAcquired
        self.state.z.vx = self.state.inventory.x.valueAcquired

        guard
        let region: RegionalAuthority = self.region else {
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

        if  self.state.type.stratum > .Ward {
            self.convert(turn: &turn, region: region.properties)
        } else {
            self.state.equity.split(
                price: self.state.z.px,
                turn: &turn,
                notifying: [region.occupiedBy]
            )
        }

        // We do not need to remove jobs that have no employees left, that will be done
        // automatically by ``Pop.turn``.
        let factoryJobs: Range<Int> = self.state.factories.values.indices
        let miningJobs: Range<Int> = self.state.mines.values.indices

        let w0: Double = .init(region.properties.minwage)
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

        let unemployed: Int64 = self.state.z.size - self.state.employed()
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
    private mutating func convert(
        turn: inout Turn,
        region: RegionalProperties,
    ) {
        let stats: PopulationStats = region.pops
        let current: PopType = self.state.type

        // when demoting, inherit 1 percent
        self.state.egress(
            evaluator: self.buildDemotionMatrix(region: region),
            inherit: 1 %/ 100,
            on: &turn,
        ) {
            current.demotes(to: $0) ? 0.01 + 0.4 * (stats.type[$0]?.employment ?? 0) : 0
        }

        // when promoting, inherit all
        self.state.egress(
            evaluator: self.buildPromotionMatrix(region: region),
            inherit: nil,
            on: &turn,
        ) {
            current.promotes(to: $0) ? 1 : 0
        }
    }

    func buildDemotionMatrix<Matrix>(
        region: RegionalProperties,
        type: Matrix.Type = Matrix.self,
    ) -> Matrix where Matrix: ConditionMatrix<Decimal, Double> {
        .init(base: 0%) {
            $0[1 - self.stats.employmentBeforeEgress] {
                $0[$1 >= 0.1] = +2‱
                $0[$1 >= 0.2] = +1‱
                $0[$1 >= 0.3] = +1‱
                $0[$1 >= 0.4] = +1‱
            } = { "\(+$0[%]): Unemployment is above \(em: $1[%0])" }

            $0[self.state.y.fl] {
                $0[$1 < 1.00] = +1‰
                $0[$1 < 0.75] = +5‰
                $0[$1 < 0.50] = +2‰
                $0[$1 < 0.25] = +2‰
            } = { "\(+$0[%]): Getting less than \(em: $1[%0]) of Life Needs" }

        } factors: {
            $0[self.state.y.fx] {
                $0[$1 > 0.25] = -90%
            } = { "\(+$0[%]): Getting more than \(em: $1[%0]) of Luxury Needs" }
            $0[self.state.y.fe] {
                $0[$1 > 0.75] = -50%
                $0[$1 > 0.5] = -25%
            } = { "\(+$0[%]): Getting more than \(em: $1[%0]) of Everyday Needs" }

            $0[self.state.y.mil] {
                $0[$1 >= 1.0] = -10%
                $0[$1 >= 2.0] = -10%
                $0[$1 >= 3.0] = -10%
                $0[$1 >= 4.0] = -10%
                $0[$1 >= 5.0] = -10%
                $0[$1 >= 6.0] = -10%
                $0[$1 >= 7.0] = -10%
                $0[$1 >= 8.0] = -10%
                $0[$1 >= 9.0] = -10%
            } = { "\(+$0[%]): Militancy is above \(em: $1[..1])" }

            let culture: Culture = region.culturePreferred
            if case .Ward = self.state.type.stratum {
                $0[true] {
                    $0 = -100%
                } = { "\(+$0[%]): Pop is \(em: "enslaved")" }
            } else if self.state.race == culture.id {
                $0[true] {
                    $0 = -5%
                } = { "\(+$0[%]): Culture is \(em: culture.name)" }
            } else {
                $0[true] {
                    $0 = +100%
                } = { "\(+$0[%]): Culture is not \(em: culture.name)" }
            }
        }
    }

    func buildPromotionMatrix<Matrix>(
        region: RegionalProperties,
        type: Matrix.Type = Matrix.self,
    ) -> Matrix where Matrix: ConditionMatrix<Decimal, Double> {
        .init(base: 0%) {
            $0[self.state.y.mil] {
                $0[$1 >= 3.0] = -2‱
                $0[$1 >= 5.0] = -2‱
                $0[$1 >= 7.0] = -3‱
                $0[$1 >= 9.0] = -3‱
            } = { "\(+$0[%]): Militancy is above \(em: $1[..1])" }

            switch self.state.type.stratum {
            case .Owner:
                $0[self.state.y.fx] {
                    $0[$1 >= 0.25] = +3‰
                    $0[$1 >= 0.50] = +3‰
                    $0[$1 >= 0.75] = +3‰
                } = { "\(+$0[%]): Getting more than \(em: $1[%0]) of Luxury Needs" }

            case _:
                break
            }

            $0[self.state.y.con] {
                $0[$1 >= 1.0] = +1‱
                $0[$1 >= 2.0] = +1‱
                $0[$1 >= 3.0] = +1‱
                $0[$1 >= 4.0] = +1‱
                $0[$1 >= 5.0] = +1‱
                $0[$1 >= 6.0] = +1‱
                $0[$1 >= 7.0] = +1‱
                $0[$1 >= 8.0] = +1‱
                $0[$1 >= 9.0] = +1‱
            } = { "\(+$0[%]): Consciousness is above \(em: $1[..1])" }

        } factors: {
            $0[self.state.y.fl] {
                $0[$1 < 1.00] = -100%
            } = { "\(+$0[%]): Getting less than \(em: $1[%0]) of Life Needs" }

            $0[self.state.y.fe] {
                $0[$1 >= 0.1] = -10%
                $0[$1 >= 0.2] = -10%
                $0[$1 >= 0.3] = -10%
                $0[$1 >= 0.4] = -10%
                $0[$1 >= 0.5] = -10%
                $0[$1 >= 0.6] = -10%
                $0[$1 >= 0.7] = -10%
                $0[$1 >= 0.8] = -10%
                $0[$1 >= 0.9] = -10%
            } = { "\(+$0[%]): Getting more than \(em: $1[%0]) of Everyday Needs" }

            $0[self.state.y.mil] {
                $0[$1 >= 2.0] = -20%
                $0[$1 >= 4.0] = -10%
                $0[$1 >= 6.0] = -10%
                $0[$1 >= 8.0] = -10%
            } = { "\(+$0[%]): Militancy is above \(em: $1[..1])" }

            let culture: Culture = region.culturePreferred
            if case .Ward = self.state.type.stratum {
                $0[true] {
                    $0 = -100%
                } = { "\(+$0[%]): Pop is \(em: "enslaved")" }
            } else if self.state.race == culture.id {
                $0[true] {
                    $0 = +5%
                } = { "\(+$0[%]): Culture is \(em: culture.name)" }
            } else {
                $0[true] {
                    $0 = -75%
                } = { "\(+$0[%]): Culture is not \(em: culture.name)" }
            }
        }
    }
}
extension PopContext {
    func explainProduction(_ ul: inout TooltipInstructionEncoder, base: Int64) {
        ul["Production per worker"] = Double.init(base)[..3]
        ul[>] {
            $0["Base"] = base[/3]
            $0["Productivity", +] = (1 as Double)[%2]
        }
    }
    func explainProduction(
        _ ul: inout TooltipInstructionEncoder,
        base: Int64,
        mine: MiningJobConditions
    ) {
        ul["Production per miner"] = (mine.factor * Double.init(base))[..3]
        ul[>] {
            $0["Base"] = base[/3]
        }

        ul["Mining efficiency"] = mine.factor[%1]
        ul[>] {
            switch self.state.type {
            case .Politician: self.explainProductionPolitician(&$0, base: base, mine: mine)
            case .Miner: self.explainProductionMiner(&$0, base: base, mine: mine)
            default: break
            }
        }
    }
    private func explainProductionPolitician(
        _ ul: inout TooltipInstructionEncoder,
        base: Int64,
        mine: MiningJobConditions
    ) {
        guard
        let mil: Double = self.region?.properties.pops.free.mil.average else {
            return
        }

        ul[>] = "Base: \(em: MineMetadata.efficiencyPoliticians[%])"
        ul["Militancy of Free Population", +] = +(
            MineMetadata.efficiencyPoliticiansPerMilitancyPoint * mil
        )[%1]
    }
    private func explainProductionMiner(
        _ ul: inout TooltipInstructionEncoder,
        base: Int64,
        mine: MiningJobConditions
    ) {
        guard
        let modifiers: CountryModifiers = self.region?.properties.modifiers,
        let modifiers: CountryModifiers.Stack<
            Decimal
        > = modifiers.miningEfficiency[mine.type] else {
            return
        }

        ul[>] = "Base: \(em: MineMetadata.efficiencyMiners[%])"
        for (effect, provenance): (Decimal, EffectProvenance) in modifiers.blame {
            ul[provenance.name, +] = +effect[%]
        }
    }

    func explainNeeds(_ ul: inout TooltipInstructionEncoder, l: Int64) {
        self.explainNeeds(&ul, base: l, needsScalePerCapita: self.state.needsScalePerCapita.l)
    }
    func explainNeeds(_ ul: inout TooltipInstructionEncoder, e: Int64) {
        self.explainNeeds(&ul, base: e, needsScalePerCapita: self.state.needsScalePerCapita.e)
    }
    func explainNeeds(_ ul: inout TooltipInstructionEncoder, x: Int64) {
        self.explainNeeds(&ul, base: x, needsScalePerCapita: self.state.needsScalePerCapita.x)
    }
    private func explainNeeds(
        _ ul: inout TooltipInstructionEncoder,
        base: Int64,
        needsScalePerCapita: Double
    ) {
        ul["Demand per capita"] = (needsScalePerCapita * Double.init(base))[..3]
        ul[>] {
            $0["Base"] = base[/3]
            $0["Consciousness", -] = +?(needsScalePerCapita - 1)[%2]
        }
    }
}
extension PopContext: LegalEntityTooltipBearing {
    func tooltipExplainPrice(
        _ line: InventoryLine,
        market: (segmented: LocalMarketSnapshot?, tradeable: WorldMarket.State?)
    ) -> Tooltip? {
        switch line {
        case .l(let id):
            return self.state.inventory.l.tooltipExplainPrice(id, market)
        case .e(let id):
            return self.state.inventory.e.tooltipExplainPrice(id, market)
        case .x(let id):
            return self.state.inventory.x.tooltipExplainPrice(id, market)
        case .o(let id):
            return self.state.inventory.out.tooltipExplainPrice(id, market)
        case .m(let id):
            return self.state.mines[id.mine]?.out.tooltipExplainPrice(id.resource, market)
        }
    }
}
extension PopContext {
    func tooltipAccount(_ account: Bank.Account) -> Tooltip? {
        let liquid: TurnDelta<Int64> = account.Δ
        let assets: TurnDelta<Int64> = self.state.Δ.vl + self.state.Δ.ve + self.state.Δ.vx
        let valuation: TurnDelta<Int64> = liquid + assets

        return .instructions {
            if case .Ward = self.state.type.stratum {
                let profit: ProfitMargins = self.state.profit
                $0["Total valuation", +] = valuation[/3]
                $0[>] {
                    $0["Today’s profit", +] = +profit.operating[/3]
                    $0["Gross margin", +] = profit.grossMargin.map {
                        (Double.init($0))[%2]
                    }
                    $0["Operating margin", +] = profit.operatingMargin.map {
                        (Double.init($0))[%2]
                    }
                }
            }

            $0["Illiquid assets", +] = assets[/3]
            $0["Liquid assets", +] = liquid[/3]
            $0[>] {
                let excluded: Int64 = self.state.spending.totalExcludingEquityPurchases
                $0["Welfare", +] = +?account.s[/3]
                $0[self.state.type.earnings, +] = +?account.r[/3]
                $0["Interest and dividends", +] = +?account.i[/3]

                $0["Market spending", +] = +?(account.b - excluded)[/3]
                $0["Stock sales", +] = +?account.j[/3]
                if case .Ward = self.state.type.stratum {
                    $0["Loans taken", +] = +?account.e[/3]
                } else {
                    $0["Investments", +] = +?account.e[/3]
                }

                $0["Inheritances", +] = +?account.d[/3]
            }
        }
    }
    func tooltipNeeds(_ tier: ResourceTierIdentifier) -> Tooltip? {
        .instructions {
            switch tier {
            case .l:
                let inputs: ResourceInputs = self.state.inventory.l
                $0["Life needs fulfilled"] = self.state.z.fl[%2]
                $0[>] {
                    $0["Market spending (amortized)", +] = inputs.valueConsumed[/3]
                    $0["Militancy", -] = +?Self.mil(fl: self.state.z.fl)[..3]
                    $0["Consciousness", -] = +?Self.con(fl: self.state.z.fl)[..3]
                }
            case .e:
                let inputs: ResourceInputs = self.state.inventory.e
                $0["Everyday needs fulfilled"] = self.state.z.fe[%2]
                $0[>] {
                    $0["Market spending (amortized)", +] = inputs.valueConsumed[/3]
                    $0["Militancy", -] = +?Self.mil(fe: self.state.z.fe)[..3]
                    $0["Consciousness", -] = +?Self.con(fe: self.state.z.fe)[..3]
                }
            case .x:
                let inputs: ResourceInputs = self.state.inventory.x
                $0["Luxury needs fulfilled"] = self.state.z.fx[%2]
                $0[>] {
                    $0["Market spending (amortized)", +] = inputs.valueConsumed[/3]
                    if let budget: Pop.Budget = self.state.budget, budget.investment > 0 {
                            $0["Investment budget", +] = budget.investment[/3]
                    }

                    $0["Militancy", -] = +?Self.mil(fx: self.state.z.fx)[..3]
                    $0["Consciousness", -] = +?Self.con(fx: self.state.z.fx)[..3]
                }
            }
        }
    }
}
