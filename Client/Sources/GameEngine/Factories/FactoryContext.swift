import Assert
import Fraction
import GameEconomy
import GameIDs
import GameRules
import GameState
import JavaScriptKit
import JavaScriptInterop
import OrderedCollections
import Random

struct FactoryContext: LegalEntityContext, RuntimeContext {
    let type: FactoryMetadata
    var state: Factory

    private(set) var governedBy: CountryProperties?
    private(set) var occupiedBy: CountryProperties?

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
        self.governedBy = nil
        self.occupiedBy = nil

        self.workers = nil
        self.clerks = nil
        self.equity = .init()

        self.cashFlow = .init()

        self.budget = nil
    }
}
extension FactoryContext {
    private static var stockpileDays: ClosedRange<Int64> { 3 ... 7 }
    static var pr: Int { 8 }

    mutating func startIndexCount() {
        if self.state.size.level == 0 {
            self.workers = nil
            self.clerks = nil
        } else {
            self.workers = .init()
            self.clerks = self.type.clerks == nil ? nil : .init()
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
                '\(self.type.name)'!
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
}
extension FactoryContext {
    mutating func compute(
        map _: borrowing GameMap,
        context: GameContext.ResidentPass
    ) throws {
        if  let area: Int64 = self.state.size.area {
            self.workers?.limit = area * self.type.workers.amount
            self.clerks?.limit = area * (self.type.clerks?.amount ?? 0)
        }

        guard
        let tile: PlanetGrid.Tile = context.planets[self.state.tile],
        let governedBy: CountryProperties = tile.governedBy,
        let occupiedBy: CountryProperties = tile.occupiedBy else {
            return
        }


        self.governedBy = governedBy
        self.occupiedBy = occupiedBy
        self.productivity = occupiedBy.factories.productivity[self.state.type]

        self.cashFlow.reset()
        self.cashFlow.update(with: self.state.inventory.l)
        self.cashFlow.update(with: self.state.inventory.e)
        self.cashFlow[.workers] = -self.state.inventory.account.w
        self.cashFlow[.clerks] = -self.state.inventory.account.c

        self.equity = .compute(equity: self.state.equity, assets: self.state.inventory.account, in: context)
    }
}
extension FactoryContext: TransactingContext {
    mutating func allocate(map: inout GameMap) {
        guard
        let country: CountryProperties = self.occupiedBy else {
            return
        }

        // Align wages with the national minimum wage.
        self.state.today.wn = max(self.state.today.wn, country.minwage)
        self.state.today.cn = max(self.state.today.cn, country.minwage)

        // Input efficiency, set to 1 for now.
        self.state.today.ei = 1

        // Reset fill positions, since they are copied from yesterday’s positions by default.
        self.state.today.wf = nil
        self.state.today.cf = nil

        let throughput: Int64 = self.workers.map {
            self.productivity * min($0.limit, $0.count + 1)
        } ?? 0

        self.state.inventory.out.sync(
            with: self.type.output,
            scalingFactor: (throughput, self.state.today.eo),
        )
        self.state.inventory.l.sync(
            with: self.type.inputs,
            scalingFactor: (throughput, self.state.today.ei),
            stockpileDays: Self.stockpileDays.lowerBound,
        )
        self.state.inventory.e.sync(
            with: self.type.office,
            scalingFactor: (throughput, self.state.today.ei),
            stockpileDays: Self.stockpileDays.lowerBound,
        )
        self.state.inventory.x.sync(
            with: self.type.costs,
            scalingFactor: (
                self.productivity * (self.state.size.level + 1),
                self.state.today.ei
            ),
            stockpileDays: Self.stockpileDays.lowerBound,
        )

        if  self.equity.sharePrice.n > 0 {
            self.state.today.px = Double.init(self.equity.sharePrice)
        } else {
            self.state.today.px = 0
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
                map: map,
            )
            budget = .init(
                workers: nil,
                clerks: nil,
                state: self.state,
                weights: weights,
                stockpileMaxDays: Self.stockpileDays.upperBound,
                d: (7, 30, 90),
            )
            sharesToIssue = max(0, self.type.sharesInitial - self.equity.shareCount)

            self.budget = .constructing(budget)
        } else {
            let unused: Double
            if  let workers: Workforce = self.workers,
                workers.limit > 0 {
                unused = min(1, Double.init(workers.limit - workers.count) / Double.init(workers.limit))
            } else {
                unused = 1
            }

            weights = .init(
                tiers: (self.state.inventory.l, self.state.inventory.e, self.state.inventory.x),
                location: self.state.tile,
                currency: country.currency.id,
                map: map,
            )
            budget = .init(
                workers: self.workers,
                clerks: self.clerks,
                state: self.state,
                weights: weights,
                stockpileMaxDays: Self.stockpileDays.upperBound,
                d: (30, 60, Int64.init(3650 * unused + 365 / (0.1 + self.state.today.pa))),
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
        map.stockMarkets.issueShares(
            currency: country.currency.id,
            quantity: sharesToIssue,
            security: self.security,
        )

        map.localMarkets.place(
            bids: (
                (budget.l.inelastic, weights.l.inelastic.x),
                (budget.e.inelastic, weights.e.inelastic.x),
                (budget.x.inelastic, weights.x.inelastic.x),
            ),
            as: self.lei,
            in: self.state.tile,
        )

        self.state.inventory.bid(in: self.state.tile, as: self.lei, on: &map)
    }

    mutating func transact(map: inout GameMap) {
        guard
        let country: CountryProperties = self.occupiedBy,
        let budget: FactoryBudget = self.budget else {
            return
        }

        let stockpileTarget: TradeableInput.StockpileTarget = .random(
            in: Self.stockpileDays,
            using: &map.random,
        )

        switch budget {
        case .constructing(let budget):
            self.state.today.pa = 1
            self.construct(
                policy: country,
                budget: budget.l,
                stockpileTarget: stockpileTarget,
                map: &map
            )

        case .liquidating(let budget):
            self.liquidate(policy: country, budget: budget, map: &map)

            self.state.today.pa = 0
            self.state.inventory.account.e -= map.bank.buyback(
                random: &map.random,
                equity: &self.state.equity,
                budget: budget.buybacks,
                security: self.security,
            )

        case .active(let budget):
            #assert(budget.workers >= 0, "Workers budget (\(budget.workers)) is negative?!?!")
            #assert(budget.clerks >= 0, "Clerks budget (\(budget.clerks)) is negative?!?!")

            #assert(self.state.size.level > 0, "Active factory has size level 0?!?!")

            if  let (salaries, bonus): (Paychecks, Double) = self.clerkEffects(
                    budget: budget.clerks,
                    map: &map
                ) {
                self.state.today.eo = 1 + bonus
                self.state.today.cn = max(
                    country.minwage,
                    self.state.today.cn + salaries.change
                )
                self.state.inventory.account.c -= salaries.paid

                switch salaries.headcount {
                case nil:
                    break
                case .fire(let block):
                    guard map.random.roll(1, 21) else {
                        break
                    }
                    map.jobs.fire.clerk[self.state.id] = block
                case .hire(let block, let type):
                    map.jobs.hire.clerk[self.state.tile.planet, type].append(block)
                }
            } else {
                self.state.today.eo = 1
            }

            let operatingProfit: Int64

            if  let workers: Workforce = self.workers {
                let wages: Paychecks = self.operate(
                    workers: workers,
                    policy: country,
                    budget: budget,
                    stockpileTarget: stockpileTarget,
                    map: &map
                )

                operatingProfit = self.state.operatingProfit

                switch wages.headcount {
                case nil:
                    break

                case .fire(let block):
                    guard map.random.roll(1, 7) else {
                        break
                    }
                    map.jobs.fire.worker[self.state.id] = block

                case .hire(let block, let type):
                    guard operatingProfit >= 0 || workers.count == 0 else {
                        break
                    }

                    map.jobs.hire.worker[self.state.tile, type].append(block)
                }
            } else {
                operatingProfit = self.state.operatingProfit
            }

            self.construct(
                policy: country,
                budget: budget.x,
                stockpileTarget: stockpileTarget,
                map: &map
            )

            self.state.inventory.account.e -= map.bank.buyback(
                random: &map.random,
                equity: &self.state.equity,
                budget: budget.buybacks,
                security: self.security,
            )
            // Pay dividends to shareholders, if any.
            self.state.inventory.account.i -= map.bank.pay(
                dividend: budget.dividend,
                to: self.state.equity.shares.values.shuffled(using: &map.random.generator)
            )

            if  self.state.size.level == 0 {
                self.state.today.pa = 1
            } else if operatingProfit > 0 {
                self.state.today.pa = min(1, self.state.today.pa + 0.01)
            } else {
                self.state.today.pa = max(0, self.state.today.pa - 0.01)
            }
        }
    }

    mutating func advance(map: inout GameMap) {
        guard case nil = self.state.liquidation,
        let country: CountryProperties = self.occupiedBy else {
            return
        }

        if  self.workers?.count ?? 0 == 0,
            self.clerks?.count ?? 0 == 0,
            self.state.yesterday.pa <= 0,
            self.state.today.pa <= 0 {
            self.state.liquidation = .init(started: map.date, burning: self.equity.shareCount)
        } else {
            self.state.equity.split(
                price: self.state.today.px,
                map: &map,
                notifying: [country.id]
            )
        }
    }
}
extension FactoryContext {
    private mutating func construct(
        policy: CountryProperties,
        budget: ResourceBudgetTier,
        stockpileTarget: TradeableInput.StockpileTarget,
        map: inout GameMap
    ) {
        if  budget.tradeable > 0 {
            let trade: TradeProceeds = self.state.inventory.x.trade(
                stockpileDays: stockpileTarget,
                spendingLimit: budget.tradeable,
                in: policy.currency.id,
                on: &map.exchange,
            )

            self.state.inventory.account.v += trade.loss
            self.state.inventory.account.r += trade.gain
        }

        let growthFactor: Int64 = self.productivity * (self.state.size.level + 1)
        if  growthFactor == self.state.inventory.x.width(limit: growthFactor, tier: self.type.costs) {
            self.state.size.grow()
            self.state.inventory.x.consume(
                from: self.type.costs,
                scalingFactor: (growthFactor, self.state.today.ei)
            )
        }

        self.state.today.vx = self.state.inventory.x.valueAcquired
    }

    private mutating func liquidate(
        policy: CountryProperties,
        budget: FactoryBudget.Liquidating,
        map: inout GameMap
    ) {
        let stockpileNone: TradeableInput.StockpileTarget = .init(lower: 0, today: 0, upper: 0)
        let tl: TradeProceeds = self.state.inventory.l.trade(
            stockpileDays: stockpileNone,
            spendingLimit: 0,
            in: policy.currency.id,
            on: &map.exchange,
        )
        let te: TradeProceeds = self.state.inventory.e.trade(
            stockpileDays: stockpileNone,
            spendingLimit: 0,
            in: policy.currency.id,
            on: &map.exchange,
        )
        let tx: TradeProceeds = self.state.inventory.x.trade(
            stockpileDays: stockpileNone,
            spendingLimit: 0,
            in: policy.currency.id,
            on: &map.exchange,
        )

        #assert(tl.loss == 0, "nl loss during liquidation is non-zero! (\(tl.loss))")
        #assert(te.loss == 0, "ne loss during liquidation is non-zero! (\(te.loss))")
        #assert(tx.loss == 0, "nx loss during liquidation is non-zero! (\(tx.loss))")

        self.state.inventory.account.r += tl.gain
        self.state.inventory.account.r += te.gain
        self.state.inventory.account.r += tx.gain

        self.state.today.vi = self.state.inventory.l.valueAcquired + self.state.inventory.e.valueAcquired
        self.state.today.vx = self.state.inventory.x.valueAcquired
    }

    private mutating func operate(
        workers: Workforce,
        policy: CountryProperties,
        budget: OperatingBudget,
        stockpileTarget: TradeableInput.StockpileTarget,
        map: inout GameMap
    ) -> Paychecks {
        self.state.inventory.account += self.state.inventory.l.trade(
            stockpileDays: stockpileTarget,
            spendingLimit: budget.l.tradeable,
            in: policy.currency.id,
            on: &map.exchange,
        )

        self.state.inventory.account += self.state.inventory.e.trade(
            stockpileDays: stockpileTarget,
            spendingLimit: budget.e.tradeable,
            in: policy.currency.id,
            on: &map.exchange,
        )

        #assert(
            self.state.inventory.account.balance >= 0,
            "Factory has negative cash! (\(self.state.inventory.account))"
        )

        let (wages, hours): (Paychecks, Int64) = self.workerEffects(
            workers: workers,
            budget: budget.workers,
            map: &map
        )

        self.state.today.wn = max(policy.minwage, self.state.today.wn + wages.change)
        self.state.inventory.account.w -= wages.paid

        /// On some days, the factory purchases more inputs than others. To get a more accurate
        /// estimate of the factory’s profitability, we need to credit the day’s balance with
        /// the amount of currency that was sunk into purchasing inputs, and subtract the
        /// approximate value of the inputs consumed today.
        let throughput: Int64 = self.productivity * hours
        self.state.inventory.l.consume(
            from: self.type.inputs,
            scalingFactor: (throughput, self.state.today.ei)
        )
        self.state.inventory.e.consume(
            from: self.type.inputs,
            scalingFactor: (throughput, self.state.today.ei)
        )
        self.state.inventory.out.deposit(
            from: self.type.output,
            scalingFactor: (throughput, self.state.today.eo)
        )

        // Sell outputs.
        self.state.inventory.account.r += self.state.inventory.out.sell(in: policy.currency.id, on: &map.exchange)

        #assert(self.state.inventory.account.balance >= 0, "Factory has negative cash! (\(self.state.inventory.account))")

        self.state.today.fi = self.state.inventory.l.fulfilled
        self.state.today.vi = self.state.inventory.l.valueAcquired + self.state.inventory.e.valueAcquired

        return wages
    }
}
extension FactoryContext {
    private func clerkEffects(
        budget: Int64,
        map: inout GameMap
    ) -> (salaries: Paychecks, bonus: Double)? {
        guard
        let clerks: Workforce = self.clerks,
        let clerkTeam: Quantity<PopType> = self.type.clerks else {
            return nil
        }

        let clerkRatio: Fraction = clerkTeam.amount %/ self.type.workers.amount
        let clerksOptimal: Int64 = self.workers.map { $0.count >< clerkRatio } ?? 0

        let owed: Int64 = clerks.count * self.state.today.cn
        let paid: Int64 = map.bank.pay(
            salariesBudget: budget,
            salaries: [
                map.payscale(shuffling: clerks.pops, rate: self.state.today.cn),
            ]
        )

        let headcount: EmployeeOperations?
        let change: Int64

        if  paid < owed {
            // Not enough money to pay all clerks.
            let retention: Fraction = paid %/ owed
            let retained: Int64 = clerks.count <> retention

            let layoff: FactoryJobLayoffBlock = .init(
                size: clerks.count - retained
            )

            if  layoff.size > 0 {
                headcount = .fire(layoff)
            } else {
                headcount = nil
            }

            change = -1

        } else {
            let clerksAffordable: Int64 = (budget - paid) / self.state.today.cn
            let clerksNeeded: Int64 = clerksOptimal - clerks.count
            let clerksToHire: Int64 = min(clerksNeeded, clerksAffordable)

            if  clerks.count < clerksNeeded,
                let p: Int = self.state.yesterday.cf,
                map.random.roll(Int64.init(p), Int64.init(Self.pr)) {
                // Was last in line to hire clerks yesterday, did not hire any clerks, and has
                // fewer than half of the target number of clerks today.
                change = 1
            } else {
                change = 0
            }

            let bid: FactoryJobOfferBlock = .init(
                at: self.state.id,
                bid: self.state.today.cn,
                size: Binomial[clerksToHire, 0.05].sample(using: &map.random.generator)
            )

            if  bid.size > 0 {
                headcount = .hire(bid, clerkTeam.unit)
            } else {
                headcount = nil
            }
        }

        let salaries: Paychecks = .init(
            change: change,
            paid: paid,
            headcount: headcount
        )

        // Compute clerk bonus in effect for today
        let bonus: Double = clerks.count < clerksOptimal
            ? Double.init(clerks.count) / Double.init(clerksOptimal)
            : 1

        return (salaries, bonus)
    }

    private func workerEffects(
        workers: Workforce,
        budget: Int64,
        map: inout GameMap
    ) -> (wages: Paychecks, hours: Int64) {
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
            budget / self.state.today.wn
        )
        let paid: Int64 = hours <= 0 ? 0 : map.bank.pay(
            wagesBudget: hours * self.state.today.wn,
            wages: map.payscale(shuffling: workers.pops, rate: self.state.today.wn)
        )

        let headcount: EmployeeOperations?
        let change: Int64

        if  hours < workers.count {
            // Not enough money to pay all workers, or not enough work to do.
            let layoff: FactoryJobLayoffBlock = .init(
                size: workers.count - hours
            )

            if  layoff.size > 0 {
                headcount = .fire(layoff)
            } else {
                headcount = nil
            }

            change = -1

        } else {
            let unspent: Int64 = budget - paid
            let open: Int64 = workers.limit - workers.count
            let hire: Int64 = min(open, unspent / self.state.today.wn)

            if  hire > 0 {
                if  workers.count < hire,
                    let p: Int = self.state.yesterday.wf,
                    map.random.roll(Int64.init(p), Int64.init(Self.pr)) {
                    // Was last in line to hire workers yesterday, did not hire any workers, and has
                    // far more inputs stockpiled than workers to process them.
                    change = 1
                } else {
                    change = 0
                }

                let bid: FactoryJobOfferBlock = .init(
                    at: self.state.id,
                    bid: self.state.today.wn,
                    size: Binomial[hire, 0.1].sample(using: &map.random.generator)
                )

                if  bid.size > 0 {
                    headcount = .hire(bid, self.type.workers.unit)
                } else {
                    headcount = nil
                }
            } else {
                headcount = nil
                change = 0
            }
        }

        let wages: Paychecks = .init(
            change: change,
            paid: paid,
            headcount: headcount
        )

        return (wages, hours)
    }
}
