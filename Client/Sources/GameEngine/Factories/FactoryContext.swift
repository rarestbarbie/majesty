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

    private var budget: FactoryBudget?

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
        self.cashFlow.update(with: self.state.ni.tradeable.values.elements)
        self.cashFlow[.workers] = -self.state.cash.w
        self.cashFlow[.clerks] = -self.state.cash.c

        self.equity = .compute(equity: self.state.equity, assets: self.state.cash, in: context)
    }
}
extension FactoryContext {
    mutating func credit(
        inelastic resource: Resource,
        units: Int64,
        price: Int64
    ) {
        let value: Int64 = units * price
        self.state.out.inelastic[resource]?.report(
            unitsSold: units,
            valueSold: value,
        )
        self.state.cash.r += value
    }

    mutating func debit(
        inelastic resource: Resource,
        units: Int64,
        price: Int64,
        tier: UInt8?
    ) {
        let value: Int64 = units * price

        switch tier {
        case 1?:
            self.state.ni.inelastic[resource]?.report(
                unitsPurchased: units,
                valuePurchased: value,
            )
        case 0?, 2?:
            // TODO: need a way to distinguish between constructing and operating phases
            self.state.nv.inelastic[resource]?.report(
                unitsPurchased: units,
                valuePurchased: value,
            )

        case _:
            return
        }

        self.state.cash.b -= value
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

        self.state.ni.sync(
            with: self.type.inputs,
            scalingFactor: (
                self.workers.map {
                    self.productivity * min($0.limit, $0.count + 1)
                } ?? 0,
                self.state.today.ei
            ),
            stockpileDays: Self.stockpileDays.lowerBound,
        )

        self.state.nv.sync(
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
                tiers: (.init(), .init(), self.state.nv),
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
                tiers: (.init(), self.state.ni, self.state.nv),
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
                d: (7, 30, Int64.init(3650 * unused + 365 / (0.1 + self.state.today.pa))),
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

        for (id, output): (Resource, InelasticOutput) in self.state.out.inelastic {
            let ask: Int64 = output.unitsProduced
            if  ask > 0 {
                map.localMarkets[self.state.tile, id].ask(amount: ask, by: self.lei)
            }
        }
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
            self.state.cash.e -= map.bank.buyback(
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
                self.state.cash.c -= salaries.paid

                switch salaries.headcount {
                case nil:
                    break
                case .fire(let block):
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

            self.state.cash.e -= map.bank.buyback(
                random: &map.random,
                equity: &self.state.equity,
                budget: budget.buybacks,
                security: self.security,
            )
            // Pay dividends to shareholders, if any.
            self.state.cash.i -= map.bank.pay(
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
            let (gain, loss): (Int64, loss: Int64) = self.state.nv.trade(
                stockpileDays: stockpileTarget,
                spendingLimit: budget.tradeable,
                in: policy.currency.id,
                on: &map.exchange,
            )

            self.state.cash.v += loss
            self.state.cash.r += gain
        }

        let growthFactor: Int64 = self.productivity * (self.state.size.level + 1)
        if  growthFactor == self.state.nv.width(limit: growthFactor, tier: self.type.costs) {
            self.state.size.grow()
            self.state.nv.consume(
                from: self.type.costs,
                scalingFactor: (growthFactor, self.state.today.ei)
            )
        }

        self.state.today.vv = self.state.nv.valueAcquired
    }

    private mutating func liquidate(
        policy: CountryProperties,
        budget: FactoryBudget.Liquidating,
        map: inout GameMap
    ) {
        let stockpileNone: TradeableInput.StockpileTarget = .init(lower: 0, today: 0, upper: 0)
        let ni: (gain: Int64, loss: Int64) = self.state.ni.trade(
            stockpileDays: stockpileNone,
            spendingLimit: 0,
            in: policy.currency.id,
            on: &map.exchange,
        )
        let nv: (gain: Int64, loss: Int64) = self.state.nv.trade(
            stockpileDays: stockpileNone,
            spendingLimit: 0,
            in: policy.currency.id,
            on: &map.exchange,
        )

        #assert(ni.loss == 0, "ni loss during liquidation is non-zero! (\(ni.loss))")
        #assert(nv.loss == 0, "nv loss during liquidation is non-zero! (\(nv.loss))")

        self.state.cash.r += ni.gain
        self.state.cash.r += nv.gain

        self.state.today.vi = self.state.ni.valueAcquired
        self.state.today.vv = self.state.nv.valueAcquired
    }

    private mutating func operate(
        workers: Workforce,
        policy: CountryProperties,
        budget: OperatingBudget,
        stockpileTarget: TradeableInput.StockpileTarget,
        map: inout GameMap
    ) -> Paychecks {
        let (gain, loss): (Int64, loss: Int64) = self.state.ni.trade(
            stockpileDays: stockpileTarget,
            spendingLimit: budget.e.tradeable,
            in: policy.currency.id,
            on: &map.exchange,
        )

        self.state.cash.b += loss
        self.state.cash.r += gain

        #assert(
            self.state.cash.balance >= 0,
            "Factory has negative cash! (\(self.state.cash))"
        )

        let (wages, hours): (Paychecks, Int64) = self.workerEffects(
            workers: workers,
            budget: budget.workers,
            map: &map
        )

        self.state.today.wn = max(policy.minwage, self.state.today.wn + wages.change)
        self.state.cash.w -= wages.paid

        /// On some days, the factory purchases more inputs than others. To get a more accurate
        /// estimate of the factory’s profitability, we need to credit the day’s balance with
        /// the amount of currency that was sunk into purchasing inputs, and subtract the
        /// approximate value of the inputs consumed today.
        self.state.ni.consume(
            from: self.type.inputs,
            scalingFactor: (self.productivity * hours, self.state.today.ei)
        )
        self.state.out.deposit(
            from: self.type.output,
            scalingFactor: (self.productivity * hours, self.state.today.eo)
        )

        // Sell outputs.
        self.state.cash.r += self.state.out.sell(in: policy.currency.id, on: &map.exchange)

        #assert(self.state.cash.balance >= 0, "Factory has negative cash! (\(self.state.cash))")

        self.state.today.fi = self.state.ni.fulfilled
        self.state.today.vi = self.state.ni.valueAcquired

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
        let hoursWorkable: Int64 = self.state.ni.width(
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
