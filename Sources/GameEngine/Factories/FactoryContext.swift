import Assert
import D
import Fraction
import GameEconomy
import GameIDs
import GameRules
import GameState
import GameUI
import OrderedCollections
import Random

struct FactoryContext: LegalEntityContext, RuntimeContext {
    let type: FactoryMetadata
    var state: Factory

    private(set) var region: RegionalProperties?

    private(set) var productivity: Int64

    private(set) var workers: Workforce?
    private(set) var clerks: Workforce?
    private(set) var equity: Equity<LEI>.Statistics
    private(set) var cashFlow: CashFlowStatement

    init(type: FactoryMetadata, state: Factory) {
        self.type = type
        self.state = state

        self.productivity = 0
        self.region = nil

        self.workers = nil
        self.clerks = nil
        self.equity = .init()
        self.cashFlow = .init()
    }
}
extension FactoryContext: Identifiable {
    var id: FactoryID { self.state.id }
}
extension FactoryContext {
    private static var stockpileDays: ClosedRange<Int64> { 3 ... 7 }

    static var efficiencyBonusFromCorporate: Double { 0.3 }
    static var pr: Int { 8 }

    mutating func startIndexCount() {
        if self.state.size.level == 0 {
            self.workers = nil
            self.clerks = nil
        } else if case _? = self.type.clerks {
            self.workers = .empty
            self.clerks = .empty
        } else {
            self.workers = .empty
            self.clerks = nil
        }
    }

    mutating func addWorkforceCount(pop: Pop, job: FactoryJob) {
        if  case pop.type = self.type.workers.unit {
            self.workers?.count(pop: pop.id, job: job)
        } else if
            case pop.type? = self.type.clerks?.unit {
            self.clerks?.count(pop: pop.id, job: job)
        } else {
            fatalError(
                """
                Pop (id = \(pop.id)) of type '\(pop.type)' cannot work in factory of type \
                '\(self.type.symbol)'!
                """
            )
        }
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
extension FactoryContext {
    mutating func afterIndexCount(
        world _: borrowing GameWorld,
        context: ComputationPass
    ) throws {
        if  let area: Int64 = self.state.size.area {
            self.workers?.limit = area * self.type.workers.amount
            self.clerks?.limit = area * (self.type.clerks?.amount ?? 0)
        }

        self.region = context.planets[self.state.tile]?.properties

        guard
        let occupiedBy: CountryProperties = self.region?.occupiedBy else {
            return
        }

        self.productivity = occupiedBy.modifiers.factoryProductivity[
            self.state.type
        ]?.value ?? 1

        self.cashFlow.reset()
        self.cashFlow.update(with: self.state.inventory.l)
        self.cashFlow.update(with: self.state.inventory.e)
        self.cashFlow[.workers] = self.state.spending.wages
        self.cashFlow[.clerks] = self.state.spending.salaries
    }
}
extension FactoryContext: TransactingContext {
    mutating func allocate(turn: inout Turn) {
        guard
        let country: CountryProperties = self.region?.occupiedBy else {
            return
        }

        // Align wages with the national minimum wage.
        self.state.z.wn = max(self.state.z.wn, country.minwage)
        self.state.z.cn = max(self.state.z.cn, country.minwage)

        #assert(
            0 ... 1 ~= self.state.y.fe,
            "Factory input efficiency out of bounds! (\(self.state.y.fe))"
        )
        // Input efficiency, bonus from buying all corporate needs yesterday.
        if  self.state.size.level == 0 {
            self.state.z.ei = 1
        } else {
            self.state.z.ei = 1 - Self.efficiencyBonusFromCorporate * .sqrt(self.state.y.fe)
        }

        // Reset fill positions, since they are copied from yesterday’s positions by default.
        self.state.z.wf = nil
        self.state.z.cf = nil

        let throughput: Int64 = self.workers.map {
            self.productivity * min($0.limit, $0.count + 1)
        } ?? 0

        self.state.inventory.out.sync(with: self.type.output, releasing: 1 %/ 4)
        self.state.inventory.l.sync(
            with: self.type.materials,
            scalingFactor: (throughput, self.state.z.ei),
        )
        self.state.inventory.e.sync(
            with: self.type.corporate,
            scalingFactor: (throughput, self.state.z.ei),
        )
        self.state.inventory.x.sync(
            with: self.type.expansion,
            scalingFactor: (
                self.productivity * (self.state.size.level + 1),
                self.state.z.ei
            ),
        )

        if  self.equity.sharePrice.n > 0 {
            self.state.z.px = Double.init(self.equity.sharePrice)
        } else {
            self.state.z.px = 0
            self.state.equity = [:]
            self.equity = .init()
        }

        if case _? = self.state.liquidation {
            self.state.budget = .liquidating(
                account: turn.bank[account: self.lei],
                sharePrice: self.equity.sharePrice
            )
            return
        }

        let weights: (segmented: SegmentedWeights<InelasticDemand>, tradeable: AggregateWeights)
        let budget: OperatingBudget
        let sharesToIssue: Int64

        if  self.state.size.level == 0 {
            weights.segmented = .businessNew(
                x: self.state.inventory.x,
                markets: turn.localMarkets,
                address: self.state.tile,
            )
            weights.tradeable = .businessNew(
                x: self.state.inventory.x,
                markets: turn.worldMarkets,
                currency: country.currency.id,
            )

            budget = .init(
                account: turn.bank[account: self.lei],
                workers: nil,
                clerks: nil,
                state: self.state.z,
                weights: weights,
                stockpileMaxDays: Self.stockpileDays.upperBound,
                d: (7, 30, 90, nil),
            )
            sharesToIssue = max(0, self.type.sharesInitial - self.equity.shareCount)

            self.state.budget = .constructing(budget)
        } else {
            let utilization: Double
            if  let workers: Workforce = self.workers,
                    workers.limit > 0 {
                utilization = min(1, Double.init(workers.count) / Double.init(workers.limit))
            } else {
                utilization = 0.5
            }

            weights.segmented = .business(
                l: self.state.inventory.l,
                e: self.state.inventory.e,
                x: self.state.inventory.x,
                markets: turn.localMarkets,
                address: self.state.tile,
            )
            weights.tradeable = .business(
                l: self.state.inventory.l,
                e: self.state.inventory.e,
                x: self.state.inventory.x,
                markets: turn.worldMarkets,
                currency: country.currency.id,
            )

            budget = .init(
                account: turn.bank[account: self.lei],
                workers: self.workers,
                clerks: self.clerks.map { ($0, self.type.clerkBonus!) },
                state: self.state.z,
                weights: weights,
                stockpileMaxDays: Self.stockpileDays.upperBound,
                d: (30, 60, 365, utilization * max(0, self.state.z.profitability))
            )

            let sharesTarget: Int64 = self.state.size.level * self.type.sharesPerLevel
                + self.type.sharesInitial
            let sharesIssued: Int64 = max(0, sharesTarget - self.equity.shareCount)

            sharesToIssue = budget.buybacks == 0 ? sharesIssued : 0

            self.state.budget = .active(budget)
        }

        // only issue shares if the factory is not performing buybacks
        // but this needs to be called even if quantity is zero, or the security will not
        // be tradeable today
        turn.stockMarkets.issueShares(
            currency: country.currency.id,
            quantity: sharesToIssue,
            security: self.security,
        )

        turn.localMarkets.tradeAsBusiness(
            selling: self.state.inventory.out.segmented,
            buying: weights.segmented,
            budget: (
                budget.l.segmented,
                budget.e.segmented,
                budget.x.segmented
            ),
            as: self.lei,
            in: self.state.tile
        )
    }

    mutating func transact(turn: inout Turn) {
        guard
        let country: CountryProperties = self.region?.occupiedBy,
        let budget: FactoryBudget = self.state.budget else {
            return
        }

        let stockpileTarget: ResourceStockpileTarget = .random(
            in: Self.stockpileDays,
            using: &turn.random,
        )

        switch budget {
        case .constructing(let budget):
            self.state.z.profitability = 1
            self.construct(
                policy: country,
                budget: budget.l,
                stockpileTarget: stockpileTarget,
                turn: &turn
            )

        case .liquidating(let budget):
            self.liquidate(policy: country, budget: budget, turn: &turn)

            self.state.z.profitability = -1
            self.state.spending.buybacks += turn.bank.buyback(
                security: self.security,
                budget: budget.buybacks,
                equity: &self.state.equity,
                random: &turn.random,
            )

        case .active(let budget):
            #assert(budget.workers >= 0, "Workers budget (\(budget.workers)) is negative?!?!")
            #assert(budget.clerks >= 0, "Clerks budget (\(budget.clerks)) is negative?!?!")

            #assert(self.state.size.level > 0, "Active factory has size level 0?!?!")

            if  let (clerks, bonus): (Update, Double) = self.clerkEffects(
                    budget: budget.clerks,
                    turn: &turn
                ) {
                self.state.spending.salaries += clerks.wagesPaid
                self.state.z.eo = 1 + bonus
                self.state.z.cn = max(
                    country.minwage,
                    self.state.z.cn + clerks.wagesChange
                )

                switch clerks.headcount {
                case nil:
                    break
                case .fire(let type, let block):
                    guard turn.random.roll(1, 21) else {
                        break
                    }
                    turn.jobs.fire[self.state.id, type] = block
                case .hire(let type, let block):
                    turn.jobs.hire.remote[self.state.tile.planet, type].append(block)
                }
            } else {
                self.state.z.eo = 1
            }

            let profit: ProfitMargins
            if  let workers: Workforce = self.workers {
                let changes: WorkforceChanges? = self.operate(
                    workers: workers,
                    policy: country,
                    budget: budget,
                    stockpileTarget: stockpileTarget,
                    turn: &turn
                )

                // can be expensive to compute, so only do it once
                profit = self.state.profit

                if case .fire(let type, let block)? = changes {
                    if  turn.random.roll(1, 7) {
                        turn.jobs.fire[self.state.id, type] = block
                    }
                } else if workers.count > 0, profit.operating < 0 {
                    if  workers.count == 1, self.clerks?.count ?? 0 == 0 {
                        // the other branch would never fire the last worker
                        if  turn.random.roll(1, profit.gross < 0 ? 7 : 30) {
                            turn.jobs.fire[self.state.id, type.workers.unit] = .init(size: 1)
                        }
                    } else {
                        /// Fire up to 40% of workers based on operating loss.
                        /// If gross profit is also negative, this happens more quickly.
                        let l: Double = max(0, -0.4 * profit.operatingProfitability)
                        let firable: Int64 = .init(l * Double.init(workers.count))
                        if  firable > 0, profit.gross < 0 || turn.random.roll(1, 3) {
                            turn.jobs.fire[self.state.id, type.workers.unit] = .init(
                                size: .random(in: 0 ... firable, using: &turn.random.generator)
                            )
                        }
                    }
                } else if case .hire(let type, let block)? = changes {
                    turn.jobs.hire.local[self.state.tile, type].append(block)
                }
            } else {
                profit = self.state.profit
            }

            self.construct(
                policy: country,
                budget: budget.x,
                stockpileTarget: stockpileTarget,
                turn: &turn
            )

            self.state.spending.buybacks += turn.bank.buyback(
                security: self.security,
                budget: budget.buybacks,
                equity: &self.state.equity,
                random: &turn.random,
            )
            // Pay dividends to shareholders, if any.
            self.state.spending.dividend += turn.bank.transfer(
                budget: budget.dividend,
                source: self.lei,
                recipients: self.state.equity.shares.values.shuffled(
                    using: &turn.random.generator
                )
            )

            self.state.z.mix(profitability: self.state.profit.operatingProfitability)
        }
    }

    mutating func advance(turn: inout Turn) {
        self.state.z.vl = self.state.inventory.l.valueAcquired
        self.state.z.ve = self.state.inventory.e.valueAcquired
        self.state.z.vx = self.state.inventory.x.valueAcquired

        guard case nil = self.state.liquidation,
        let country: CountryProperties = self.region?.occupiedBy else {
            return
        }

        if  self.workers?.count ?? 0 == 0,
            self.clerks?.count ?? 0 == 0,
            self.state.y.profitability <= 0,
            self.state.z.profitability <= 0 {
            self.state.liquidation = .init(started: turn.date, burning: self.equity.shareCount)
        } else {
            self.state.equity.split(
                price: self.state.z.px,
                turn: &turn,
                notifying: [country.id]
            )
        }
    }
}
extension FactoryContext {
    private mutating func construct(
        policy: CountryProperties,
        budget: ResourceBudgetTier,
        stockpileTarget: ResourceStockpileTarget,
        turn: inout Turn
    ) {
        if  budget.tradeable > 0 {
            {
                $0 += self.state.inventory.x.tradeAsBusiness(
                    stockpileDays: stockpileTarget,
                    spendingLimit: budget.tradeable,
                    in: policy.currency.id,
                    on: &turn.worldMarkets,
                )
            } (&turn.bank[account: self.lei])
        }

        let growthFactor: Int64 = self.productivity * (self.state.size.level + 1)
        if  self.state.inventory.x.full {
            self.state.size.grow()
            self.state.inventory.x.consume(
                from: self.type.expansion,
                scalingFactor: (growthFactor, self.state.z.ei)
            )
        }

        self.state.z.fx = self.state.inventory.x.fulfilled
    }

    private mutating func liquidate(
        policy: CountryProperties,
        budget: LiquidationBudget,
        turn: inout Turn
    ) {
        {
            let stockpileNone: ResourceStockpileTarget = .init(lower: 0, today: 0, upper: 0)
            let tl: TradeProceeds = self.state.inventory.l.tradeAsBusiness(
                stockpileDays: stockpileNone,
                spendingLimit: 0,
                in: policy.currency.id,
                on: &turn.worldMarkets,
            )
            let te: TradeProceeds = self.state.inventory.e.tradeAsBusiness(
                stockpileDays: stockpileNone,
                spendingLimit: 0,
                in: policy.currency.id,
                on: &turn.worldMarkets,
            )
            let tx: TradeProceeds = self.state.inventory.x.tradeAsBusiness(
                stockpileDays: stockpileNone,
                spendingLimit: 0,
                in: policy.currency.id,
                on: &turn.worldMarkets,
            )

            #assert(tl.loss == 0, "nl loss during liquidation is non-zero! (\(tl.loss))")
            #assert(te.loss == 0, "ne loss during liquidation is non-zero! (\(te.loss))")
            #assert(tx.loss == 0, "nx loss during liquidation is non-zero! (\(tx.loss))")

            let proceeds: Int64 = tl.gain + te.gain + tx.gain
            $0.r += proceeds
        } (&turn.bank[account: self.lei])
    }

    private mutating func operate(
        workers: Workforce,
        policy: CountryProperties,
        budget: OperatingBudget,
        stockpileTarget: ResourceStockpileTarget,
        turn: inout Turn
    ) -> WorkforceChanges? {
        {
            $0 += self.state.inventory.l.tradeAsBusiness(
                stockpileDays: stockpileTarget,
                spendingLimit: budget.l.tradeable,
                in: policy.currency.id,
                on: &turn.worldMarkets,
            )
            $0 += self.state.inventory.e.tradeAsBusiness(
                stockpileDays: stockpileTarget,
                spendingLimit: budget.e.tradeable,
                in: policy.currency.id,
                on: &turn.worldMarkets,
            )

            #assert(
                $0.balance >= 0,
                """
                Factory (id = \(self.id), type = '\(self.type.symbol)') has negative cash! \
                (\($0))
                """
            )

            $0.r += self.state.inventory.out.sell(
                in: policy.currency.id,
                on: &turn.worldMarkets
            )
        } (&turn.bank[account: self.lei])

        let (update, hours): (Update, Int64) = self.workerEffects(
            workers: workers,
            budget: budget.workers,
            turn: &turn
        )

        self.state.z.wn = max(policy.minwage, self.state.z.wn + update.wagesChange)
        self.state.spending.wages += update.wagesPaid

        /// On some days, the factory purchases more inputs than others. To get a more accurate
        /// estimate of the factory’s profitability, we need to credit the day’s balance with
        /// the amount of currency that was sunk into purchasing inputs, and subtract the
        /// approximate value of the inputs consumed today.
        let throughput: Int64 = self.productivity * hours
        self.state.inventory.l.consume(
            from: self.type.materials,
            scalingFactor: (throughput, self.state.z.ei)
        )
        self.state.inventory.e.consume(
            from: self.type.corporate,
            scalingFactor: (throughput, self.state.z.ei * budget.corporate)
        )

        self.state.inventory.out.deposit(
            from: self.type.output,
            scalingFactor: (throughput, self.state.z.eo)
        )

        self.state.z.fl = self.state.inventory.l.fulfilled
        // `fulfilled` counts stockpiled resources that were saved for the next day,
        // so to compute the actual usage today we need `min` it with the consumption fraction
        self.state.z.fe = min(self.state.inventory.e.fulfilled, budget.corporate)

        return update.headcount
    }
}
extension FactoryContext {
    private var clerkEffects: ClerkEffects? {
        guard
        let clerks: Workforce = self.clerks,
        let clerkTeam: FactoryMetadata.ClerkBonus = self.type.clerkBonus else {
            return nil
        }

        let optimal: Int64 = self.workers.map { clerkTeam.optimal(for: $0.count) } ?? 0
        return .init(
            workforce: clerks,
            optimal: optimal,
            bonus: clerks.count < optimal
                ? Double.init(clerks.count) / Double.init(optimal)
                : 1,
            clerk: clerkTeam.type,
        )
    }

    private func clerkEffects(
        budget: Int64,
        turn: inout Turn
    ) -> (salaries: Update, bonus: Double)? {
        guard
        let clerks: ClerkEffects = self.clerkEffects else {
            return nil
        }

        let wagesOwed: Int64 = clerks.workforce.count * self.state.z.cn
        let wagesPaid: Int64 = turn.bank.transfer(
            budget: budget,
            source: self.lei,
            recipients: turn.payscale(shuffling: clerks.workforce.pops, rate: self.state.z.cn),
        )

        let headcount: WorkforceChanges?
        let wagesChange: Int64

        if  wagesPaid < wagesOwed {
            // Not enough money to pay all clerks.
            let retention: Fraction = wagesPaid %/ wagesOwed
            let retained: Int64 = clerks.workforce.count <> retention

            if  let layoff: PopJobLayoffBlock = .init(size: clerks.workforce.count - retained) {
                headcount = .fire(clerks.clerk, layoff)
            } else {
                headcount = nil
            }

            wagesChange = -1
        } else if let layoff: PopJobLayoffBlock = .init(
                size: clerks.workforce.count - clerks.optimal
            ) {
            headcount = .fire(clerks.clerk, layoff)
            wagesChange = 0
        } else {
            let clerksAffordable: Int64 = (budget - wagesPaid) / self.state.z.cn
            let clerksNeeded: Int64 = clerks.optimal - clerks.workforce.count
            let clerksToHire: Int64 = min(clerksNeeded, clerksAffordable)

            if  clerks.workforce.count < clerksNeeded,
                let p: Int = self.state.y.cf,
                turn.random.roll(Int64.init(p), Int64.init(Self.pr)) {
                // Was last in line to hire clerks yesterday, did not hire any clerks, and has
                // fewer than half of the target number of clerks today.
                wagesChange = 1
            } else {
                wagesChange = 0
            }

            let bid: PopJobOfferBlock = .init(
                job: .factory(self.state.id),
                bid: self.state.z.cn,
                size: .random(
                    in: 0 ... max(1, clerksToHire / 20),
                    using: &turn.random.generator
                )
            )

            if  bid.size > 0 {
                headcount = .hire(clerks.clerk, bid)
            } else {
                headcount = nil
            }
        }

        let update: Update = .init(
            wagesChange: wagesChange,
            wagesPaid: wagesPaid,
            headcount: headcount
        )

        return (update, clerks.bonus)
    }

    private func workerEffects(
        workers: Workforce,
        budget: Int64,
        turn: inout Turn
    ) -> (wages: Update, hours: Int64) {
        /// Compute hours workable, assuming each worker works 1 “hour” per day for mathematical
        /// convenience. This can be larger than the actual number of workers available, but it
        /// will never be larger than the number of workers that can fit in the factory.
        let hoursWorkable: Int64 = self.state.inventory.l.width(
            limit: workers.limit,
            tier: self.type.materials,
            efficiency: self.state.z.ei
        )

        #assert(hoursWorkable >= 0, "Hours workable (\(hoursWorkable)) is negative?!?!")

        let hours: Int64 = min(
            min(workers.count, hoursWorkable),
            budget / self.state.z.wn
        )
        let wagesPaid: Int64 = hours <= 0 ? 0 : turn.bank.transfer(
            budget: hours * self.state.z.wn,
            source: self.lei,
            recipients: turn.payscale(shuffling: workers.pops, rate: self.state.z.wn)
        )

        let headcount: WorkforceChanges?
        let wagesChange: Int64

        if  hours < workers.count {
            // Not enough money to pay all workers, or not enough work to do.
            if  let layoff: PopJobLayoffBlock = .init(size: workers.count - hours) {
                headcount = .fire(self.type.workers.unit, layoff)
            } else {
                headcount = nil
            }

            wagesChange = -1

        } else {
            let unspent: Int64 = budget - wagesPaid
            let open: Int64 = workers.limit - workers.count
            let hire: Int64 = min(open, unspent / self.state.z.wn)

            if  hire > 0 {
                if  workers.count < hire,
                    let p: Int = self.state.y.wf,
                    turn.random.roll(Int64.init(p), Int64.init(Self.pr)) {
                    // Was last in line to hire workers yesterday, did not hire any workers, and has
                    // far more inputs stockpiled than workers to process them.
                    wagesChange = 1
                } else {
                    wagesChange = 0
                }

                let bid: PopJobOfferBlock = .init(
                    job: .factory(self.state.id),
                    bid: self.state.z.wn,
                    size: .random(
                        in: 0 ... max(1, hire / 10),
                        using: &turn.random.generator
                    )
                )

                if  bid.size > 0 {
                    headcount = .hire(self.type.workers.unit, bid)
                } else {
                    headcount = nil
                }
            } else {
                headcount = nil
                wagesChange = 0
            }
        }

        let update: Update = .init(
            wagesChange: wagesChange,
            wagesPaid: wagesPaid,
            headcount: headcount
        )

        return (update, hours)
    }
}
extension FactoryContext {
    func explainProduction(_ ul: inout TooltipInstructionEncoder, base: Int64) {
        let productivity: Double = Double.init(self.productivity)
        let efficiency: Double = self.state.z.eo
        ul["Production per worker"] = (productivity * efficiency * Double.init(base))[..3]
        ul[>] {
            $0["Base"] = base[/3]
            $0["Productivity", +] = productivity[%2]
            $0["Efficiency", +] = +?(efficiency - 1)[%2]
        }
    }

    func explainNeeds(_ ul: inout TooltipInstructionEncoder, x: Int64) {
        self.explainNeeds(&ul, base: x, unit: "level")
    }
    func explainNeeds(_ ul: inout TooltipInstructionEncoder, base: Int64) {
        self.explainNeeds(&ul, base: base, unit: "worker")
    }
    private func explainNeeds(
        _ ul: inout TooltipInstructionEncoder,
        base: Int64,
        unit: String
    ) {
        let productivity: Double = Double.init(self.productivity)
        let efficiency: Double = self.state.z.ei
        ul["Demand per \(unit)"] = (productivity * efficiency * Double.init(base))[..3]
        ul[>] {
            $0["Base"] = base[/3]
            $0["Productivity", +] = productivity[%2]
            $0["Efficiency", -] = +?(efficiency - 1)[%2]
        }
    }
}
extension FactoryContext {
    func tooltipAccount(_ account: Bank.Account) -> Tooltip? {
        let profit: ProfitMargins = self.state.profit
        let liquid: TurnDelta<Int64> = account.Δ
        let assets: TurnDelta<Int64> = self.state.Δ.vl + self.state.Δ.ve + self.state.Δ.vx

        return .instructions {
            $0["Total valuation", +] = (liquid + assets)[/3]
            $0[>] {
                $0["Today’s profit", +] = +profit.operating[/3]
                $0["Gross margin", +] = profit.grossMargin.map {
                    (Double.init($0))[%2]
                }
                $0["Operating margin", +] = profit.operatingMargin.map {
                    (Double.init($0))[%2]
                }
            }

            $0["Illiquid assets", +] = assets[/3]
            $0["Liquid assets", +] = liquid[/3]
            $0[>] {
                let excluded: Int64 = self.state.spending.totalExcludingEquityPurchases
                $0["Market spending", +] = +(account.b + excluded)[/3]
                $0["Market earnings", +] = +?account.r[/3]
                $0["Subsidies", +] = +?account.s[/3]
                $0["Salaries", +] = +?(-self.state.spending.salaries)[/3]
                $0["Wages", +] = +?(-self.state.spending.wages)[/3]
                $0["Interest and dividends", +] = +?(-self.state.spending.dividend)[/3]
                $0["Stock buybacks", +] = (-self.state.spending.buybacks)[/3]
                if account.e > 0 {
                    $0["Market capitalization", +] = +account.e[/3]
                }
            }
        }
    }

    func tooltipWorkers() -> Tooltip? {
        guard let workforce: Workforce = self.workers else {
            return nil
        }
        return .instructions {
            $0[self.type.workers.unit.plural] = workforce.count[/3] / workforce.limit
            $0["Current wage"] = self.state.Δ.wn[/3]
            workforce.explainChanges(&$0)
        }
    }
    func tooltipClerks() -> Tooltip? {
        guard let clerks: ClerkEffects = self.clerkEffects else {
            return nil
        }
        return .instructions {
            $0[clerks.clerk.plural] = clerks.workforce.count[/3] / clerks.workforce.limit
            $0[>] {
                $0["Output bonus", +] = +clerks.bonus[%2]
            }
            $0["Current salary"] = self.state.Δ.wn[/3]
            $0[>] = """
            The optimal number of clerks for this factory is \(
                clerks.optimal,
                style: clerks.workforce.count <= clerks.optimal ? .em : .neg
            )
            """
            $0[>] = """
            Clerks help factories produce more, but are also much harder to fire
            """
            clerks.workforce.explainChanges(&$0)
        }
    }

    func tooltipNeeds(
        _ tier: ResourceTierIdentifier
    ) -> Tooltip? {
        .instructions {
            switch tier {
            case .l:
                let inputs: ResourceInputs = self.state.inventory.l
                $0["Materials fulfilled"] = self.state.z.fl[%3]
                $0[>] {
                    $0["Market spending (amortized)", +] = inputs.valueConsumed[/3]
                    $0["Efficiency", -] = +?(self.state.z.ei - 1)[%2]
                }
                $0[>] = """
                Factories that lack materials will not produce anything
                """
            case .e:
                let inputs: ResourceInputs = self.state.inventory.e
                $0["Corporate supplies"] = self.state.z.fe[%3]
                $0[>] {
                    $0["Market spending (amortized)", +] = inputs.valueConsumed[/3]
                    $0["Efficiency", -] = +?(self.state.z.ei - 1)[%2]
                }
                $0[>] = self.state.z.ei < 1 ? """
                Today this factory saved \(pos: (1 - self.state.z.ei)[%1]) on all inputs
                """ : """
                Factories that purchase all of their corporate supplies are more efficient
                """

                if case .active(let budget)? = self.state.budget, budget.corporate < 1 {
                    $0[>] = """
                    Due to high \(em: "corporate costs"), this factory is only purchasing \
                    \(neg: (100 * budget.corporate)[..1]) percent of its corporate supplies
                    """
                }
            case .x:
                let inputs: ResourceInputs = self.state.inventory.x
                $0["Capital expenditures"] = self.state.z.fx[%3]
                $0[>] {
                    $0["Market spending (amortized)", +] = inputs.valueConsumed[/3]
                    $0["Efficiency", -] = +?(self.state.z.ei - 1)[%2]
                }
            }
        }
    }

    func tooltipSize() -> Tooltip {
        .instructions {
            $0["Effective size"] = self.state.size.area?[/3]
            $0["Growth progress"] = self.state.size.growthProgress[/0]
                / Factory.Size.growthRequired

            if  let liquidation: FactoryLiquidation = self.state.liquidation {
                let shareCount: Int64 = self.equity.shareCount
                $0[>] = """
                This factory has been in bankruptcy proceedings since \
                \(em: liquidation.started[.phrasal_US]) and there \(
                    shareCount == 1 ? "is" : "are"
                ) \(neg: shareCount) \(
                    shareCount == 1 ? "share" : "shares"
                ) left to liquidate
                """
            } else {
                $0[>] = """
                Doubling the factory level will quadruple its capacity
                """
            }
        }
    }

    func tooltipSummarizeEmployees(_ stratum: PopStratum) -> Tooltip? {
        let workforce: Workforce
        let type: PopType

        if case .Worker = stratum,
            let workers: Workforce = self.workers {
            workforce = workers
            type = self.type.workers.unit
        } else if
            let clerks: Workforce = self.clerks,
            let clerkTeam: Quantity<PopType> = self.type.clerks {
            workforce = clerks
            type = clerkTeam.unit
        } else {
            return nil
        }

        return .instructions {
            $0[type.plural] = workforce.count[/3] / workforce.limit
            workforce.explainChanges(&$0)
        }
    }
}
