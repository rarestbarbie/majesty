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
    private(set) var budget: FactoryBudget?

    init(type: FactoryMetadata, state: Factory) {
        self.type = type
        self.state = state

        self.productivity = 0
        self.region = nil

        self.workers = nil
        self.clerks = nil
        self.equity = .init()

        self.cashFlow = .init()

        self.budget = nil
    }
}
extension FactoryContext: Identifiable {
    var id: FactoryID { self.state.id }
}
extension FactoryContext {
    private static var stockpileDays: ClosedRange<Int64> { 3 ... 7 }
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
    mutating func compute(world _: borrowing GameWorld, context: ComputationPass) throws {
        if  let area: Int64 = self.state.size.area {
            self.workers?.limit = area * self.type.workers.amount
            self.clerks?.limit = area * (self.type.clerks?.amount ?? 0)
        }

        self.region = context.planets[self.state.tile]?.properties

        guard
        let occupiedBy: CountryProperties = self.region?.occupiedBy else {
            return
        }

        self.productivity = occupiedBy.modifiers.factoryProductivity[self.state.type]?.value ?? 1

        self.cashFlow.reset()
        self.cashFlow.update(with: self.state.inventory.l)
        self.cashFlow.update(with: self.state.inventory.e)
        self.cashFlow[.workers] = -self.state.inventory.account.w
        self.cashFlow[.clerks] = -self.state.inventory.account.c
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

        // Input efficiency, set to 1 for now.
        self.state.z.ei = 1

        // Reset fill positions, since they are copied from yesterday’s positions by default.
        self.state.z.wf = nil
        self.state.z.cf = nil

        let throughput: Int64 = self.workers.map {
            self.productivity * min($0.limit, $0.count + 1)
        } ?? 0

        self.state.inventory.out.sync(with: self.type.output, releasing: 1 %/ 4)
        self.state.inventory.l.sync(
            with: self.type.inputs,
            scalingFactor: (throughput, self.state.z.ei),
        )
        self.state.inventory.e.sync(
            with: self.type.office,
            scalingFactor: (throughput, self.state.z.ei),
        )
        self.state.inventory.x.sync(
            with: self.type.costs,
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
            self.budget = .liquidating(state: self.state, sharePrice: self.equity.sharePrice)
            return
        }

        let weights: ResourceInputWeights
        let budget: OperatingBudget
        let sharesToIssue: Int64

        if  self.state.size.level == 0 {
            weights = .init(
                tiers: (.init(), .init(), self.state.inventory.x),
                location: self.state.tile,
                currency: country.currency.id,
                turn: turn,
            )
            budget = .init(
                workers: nil,
                clerks: nil,
                state: self.state,
                weights: weights,
                stockpileMaxDays: Self.stockpileDays.upperBound,
                d: (7, 30, 90, nil),
            )
            sharesToIssue = max(0, self.type.sharesInitial - self.equity.shareCount)

            self.budget = .constructing(budget)
        } else {
            let utilization: Double
            if  let workers: Workforce = self.workers,
                workers.limit > 0 {
                utilization = min(1, Double.init(workers.count) / Double.init(workers.limit))
            } else {
                utilization = 0.5
            }

            weights = .init(
                tiers: (self.state.inventory.l, self.state.inventory.e, self.state.inventory.x),
                location: self.state.tile,
                currency: country.currency.id,
                turn: turn,
            )
            budget = .init(
                workers: self.workers,
                clerks: self.clerks.map { ($0, self.type.clerkBonus!) },
                state: self.state,
                weights: weights,
                stockpileMaxDays: Self.stockpileDays.upperBound,
                d: (30, 60, 365, utilization * self.state.z.pa)
            )

            let sharesTarget: Int64 = self.state.size.level * self.type.sharesPerLevel
                + self.type.sharesInitial
            let sharesIssued: Int64 = max(0, sharesTarget - self.equity.shareCount)

            sharesToIssue = budget.buybacks == 0 ? sharesIssued : 0

            self.budget = .active(budget)
        }

        // only issue shares if the factory is not performing buybacks
        // but this needs to be called even if quantity is zero, or the security will not
        // be tradeable today
        turn.stockMarkets.issueShares(
            currency: country.currency.id,
            quantity: sharesToIssue,
            security: self.security,
        )

        turn.localMarkets.place(
            bids: (
                (budget.l.inelastic, weights.l.inelastic.x),
                (budget.e.inelastic, weights.e.inelastic.x),
                (budget.x.inelastic, weights.x.inelastic.x),
            ),
            asks: self.state.inventory.out.inelastic,
            as: self.lei,
            in: self.state.tile,
        )
    }

    mutating func transact(turn: inout Turn) {
        guard
        let country: CountryProperties = self.region?.occupiedBy,
        let budget: FactoryBudget = self.budget else {
            return
        }

        let stockpileTarget: ResourceStockpileTarget = .random(
            in: Self.stockpileDays,
            using: &turn.random,
        )

        switch budget {
        case .constructing(let budget):
            self.state.z.pa = 1
            self.construct(
                policy: country,
                budget: budget.l,
                stockpileTarget: stockpileTarget,
                turn: &turn
            )

        case .liquidating(let budget):
            self.liquidate(policy: country, budget: budget, turn: &turn)

            self.state.z.pa = 0
            self.state.inventory.account.e -= turn.bank.buyback(
                random: &turn.random,
                equity: &self.state.equity,
                budget: budget.buybacks,
                security: self.security,
            )

        case .active(let budget):
            #assert(budget.workers >= 0, "Workers budget (\(budget.workers)) is negative?!?!")
            #assert(budget.clerks >= 0, "Clerks budget (\(budget.clerks)) is negative?!?!")

            #assert(self.state.size.level > 0, "Active factory has size level 0?!?!")

            if  let (clerks, bonus): (Update, Double) = self.clerkEffects(
                    budget: budget.clerks,
                    turn: &turn
                ) {
                self.state.z.eo = 1 + bonus
                self.state.z.cn = max(
                    country.minwage,
                    self.state.z.cn + clerks.wagesChange
                )
                self.state.inventory.account.c -= clerks.wagesPaid

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

            let operatingProfit: Int64

            if  let workers: Workforce = self.workers {
                let changes: WorkforceChanges? = self.operate(
                    workers: workers,
                    policy: country,
                    budget: budget,
                    stockpileTarget: stockpileTarget,
                    turn: &turn
                )

                operatingProfit = self.state.operatingProfit

                if case .fire(let type, let block)? = changes {
                    if  turn.random.roll(1, 7) {
                        turn.jobs.fire[self.state.id, type] = block
                    }
                } else if workers.count > 0, operatingProfit < 0 {
                    let firable: Int64 = workers.count / 4
                    if  firable > 0, turn.random.roll(1, 7) {
                        turn.jobs.fire[self.state.id, type.workers.unit] = .init(
                            size: .random(in: 0 ... firable, using: &turn.random.generator)
                        )
                    }
                } else if case .hire(let type, let block)? = changes {
                    turn.jobs.hire.local[self.state.tile, type].append(block)
                }
            } else {
                operatingProfit = self.state.operatingProfit
            }

            self.construct(
                policy: country,
                budget: budget.x,
                stockpileTarget: stockpileTarget,
                turn: &turn
            )

            self.state.inventory.account.e -= turn.bank.buyback(
                random: &turn.random,
                equity: &self.state.equity,
                budget: budget.buybacks,
                security: self.security,
            )
            // Pay dividends to shareholders, if any.
            self.state.inventory.account.i -= turn.bank.pay(
                dividend: budget.dividend,
                to: self.state.equity.shares.values.shuffled(using: &turn.random.generator)
            )

            if  self.state.size.level == 0 {
                self.state.z.pa = 1
            } else if operatingProfit > 0 {
                self.state.z.pa = min(1, self.state.z.pa + 0.01)
            } else {
                self.state.z.pa = max(0, self.state.z.pa - 0.01)
            }
        }
    }

    mutating func advance(turn: inout Turn) {
        guard case nil = self.state.liquidation,
        let country: CountryProperties = self.region?.occupiedBy else {
            return
        }

        if  self.workers?.count ?? 0 == 0,
            self.clerks?.count ?? 0 == 0,
            self.state.y.pa <= 0,
            self.state.z.pa <= 0 {
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
            let trade: TradeProceeds = self.state.inventory.x.trade(
                stockpileDays: stockpileTarget,
                spendingLimit: budget.tradeable,
                in: policy.currency.id,
                on: &turn.worldMarkets,
            )

            self.state.inventory.account.v += trade.loss
            self.state.inventory.account.r += trade.gain
        }

        let growthFactor: Int64 = self.productivity * (self.state.size.level + 1)
        if  growthFactor == self.state.inventory.x.width(
                limit: growthFactor,
                tier: self.type.costs
            ) {
            self.state.size.grow()
            self.state.inventory.x.consume(
                from: self.type.costs,
                scalingFactor: (growthFactor, self.state.z.ei)
            )
        }

        self.state.z.fx = self.state.inventory.x.fulfilled
        self.state.z.vx = self.state.inventory.x.valueAcquired
    }

    private mutating func liquidate(
        policy: CountryProperties,
        budget: FactoryBudget.Liquidating,
        turn: inout Turn
    ) {
        let stockpileNone: ResourceStockpileTarget = .init(lower: 0, today: 0, upper: 0)
        let tl: TradeProceeds = self.state.inventory.l.trade(
            stockpileDays: stockpileNone,
            spendingLimit: 0,
            in: policy.currency.id,
            on: &turn.worldMarkets,
        )
        let te: TradeProceeds = self.state.inventory.e.trade(
            stockpileDays: stockpileNone,
            spendingLimit: 0,
            in: policy.currency.id,
            on: &turn.worldMarkets,
        )
        let tx: TradeProceeds = self.state.inventory.x.trade(
            stockpileDays: stockpileNone,
            spendingLimit: 0,
            in: policy.currency.id,
            on: &turn.worldMarkets,
        )

        #assert(tl.loss == 0, "nl loss during liquidation is non-zero! (\(tl.loss))")
        #assert(te.loss == 0, "ne loss during liquidation is non-zero! (\(te.loss))")
        #assert(tx.loss == 0, "nx loss during liquidation is non-zero! (\(tx.loss))")

        self.state.inventory.account.r += tl.gain
        self.state.inventory.account.r += te.gain
        self.state.inventory.account.r += tx.gain

        self.state.z.vi = self.state.inventory.l.valueAcquired + self.state.inventory.e.valueAcquired
        self.state.z.vx = self.state.inventory.x.valueAcquired
    }

    private mutating func operate(
        workers: Workforce,
        policy: CountryProperties,
        budget: OperatingBudget,
        stockpileTarget: ResourceStockpileTarget,
        turn: inout Turn
    ) -> WorkforceChanges? {
        self.state.inventory.account += self.state.inventory.l.trade(
            stockpileDays: stockpileTarget,
            spendingLimit: budget.l.tradeable,
            in: policy.currency.id,
            on: &turn.worldMarkets,
        )

        self.state.inventory.account += self.state.inventory.e.trade(
            stockpileDays: stockpileTarget,
            spendingLimit: budget.e.tradeable,
            in: policy.currency.id,
            on: &turn.worldMarkets,
        )

        #assert(
            self.state.inventory.account.balance >= 0,
            """
            Factory (id = \(self.id), type = '\(self.type.symbol)') has negative cash! \
            (\(self.state.inventory.account))
            """
        )

        let (update, hours): (Update, Int64) = self.workerEffects(
            workers: workers,
            budget: budget.workers,
            turn: &turn
        )

        self.state.z.wn = max(policy.minwage, self.state.z.wn + update.wagesChange)
        self.state.inventory.account.w -= update.wagesPaid

        /// On some days, the factory purchases more inputs than others. To get a more accurate
        /// estimate of the factory’s profitability, we need to credit the day’s balance with
        /// the amount of currency that was sunk into purchasing inputs, and subtract the
        /// approximate value of the inputs consumed today.
        let throughput: Int64 = self.productivity * hours
        self.state.inventory.l.consume(
            from: self.type.inputs,
            scalingFactor: (throughput, self.state.z.ei)
        )
        self.state.inventory.e.consume(
            from: self.type.office,
            scalingFactor: (throughput, self.state.z.ei)
        )

        self.state.inventory.account.r += self.state.inventory.out.sell(
            in: policy.currency.id,
            on: &turn.worldMarkets
        )
        self.state.inventory.out.deposit(
            from: self.type.output,
            scalingFactor: (throughput, self.state.z.eo)
        )

        #assert(
            self.state.inventory.account.balance >= 0,
            "Factory has negative cash! (\(self.state.inventory.account))"
        )

        self.state.z.fl = self.state.inventory.l.fulfilled
        self.state.z.fe = self.state.inventory.e.fulfilled
        self.state.z.vi = self.state.inventory.l.valueAcquired + self.state.inventory.e.valueAcquired

        return update.headcount
    }
}
extension FactoryMetadata {
    var clerkBonus: ClerkBonus? {
        guard
        let clerks: Quantity<PopType> = self.clerks else {
            return nil
        }
        return .init(ratio: clerks.amount %/ self.workers.amount, type: clerks.unit)
    }
}
extension FactoryMetadata {
    struct ClerkBonus {
        let ratio: Fraction
        let type: PopType
    }
}
extension FactoryMetadata.ClerkBonus {
    func optimal(for workers: Int64) -> Int64 {
        workers >< self.ratio
    }
}
extension FactoryContext {
    private func clerkEffects(
        budget: Int64,
        turn: inout Turn
    ) -> (salaries: Update, bonus: Double)? {
        guard
        let clerks: Workforce = self.clerks,
        let clerkTeam: FactoryMetadata.ClerkBonus = self.type.clerkBonus else {
            return nil
        }

        let clerksOptimal: Int64 = self.workers.map { clerkTeam.optimal(for: $0.count) } ?? 0

        let wagesOwed: Int64 = clerks.count * self.state.z.cn
        let wagesPaid: Int64 = turn.bank.pay(
            salariesBudget: budget,
            salaries: [
                turn.payscale(shuffling: clerks.pops, rate: self.state.z.cn),
            ]
        )

        let headcount: WorkforceChanges?
        let wagesChange: Int64

        if  wagesPaid < wagesOwed {
            // Not enough money to pay all clerks.
            let retention: Fraction = wagesPaid %/ wagesOwed
            let retained: Int64 = clerks.count <> retention

            if  let layoff: PopJobLayoffBlock = .init(size: clerks.count - retained) {
                headcount = .fire(clerkTeam.type, layoff)
            } else {
                headcount = nil
            }

            wagesChange = -1
        } else if let layoff: PopJobLayoffBlock = .init(size: clerks.count - clerksOptimal) {
            headcount = .fire(clerkTeam.type, layoff)
            wagesChange = 0
        } else {
            let clerksAffordable: Int64 = (budget - wagesPaid) / self.state.z.cn
            let clerksNeeded: Int64 = clerksOptimal - clerks.count
            let clerksToHire: Int64 = min(clerksNeeded, clerksAffordable)

            if  clerks.count < clerksNeeded,
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
                headcount = .hire(clerkTeam.type, bid)
            } else {
                headcount = nil
            }
        }

        let update: Update = .init(
            wagesChange: wagesChange,
            wagesPaid: wagesPaid,
            headcount: headcount
        )

        // Compute clerk bonus in effect for today
        let bonus: Double = clerks.count < clerksOptimal
            ? Double.init(clerks.count) / Double.init(clerksOptimal)
            : 1

        return (update, bonus)
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
            tier: self.type.inputs
        )

        #assert(hoursWorkable >= 0, "Hours workable (\(hoursWorkable)) is negative?!?!")

        let hours: Int64 = min(
            min(workers.count, hoursWorkable),
            budget / self.state.z.wn
        )
        let wagesPaid: Int64 = hours <= 0 ? 0 : turn.bank.pay(
            wagesBudget: hours * self.state.z.wn,
            wages: turn.payscale(shuffling: workers.pops, rate: self.state.z.wn)
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
}
