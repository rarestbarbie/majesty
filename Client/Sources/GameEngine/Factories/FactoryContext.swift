import Assert
import GameEconomy
import GameRules
import GameState
import JavaScriptKit
import JavaScriptInterop
import OrderedCollections
import Random

struct FactoryContext: RuntimeContext {
    let type: FactoryMetadata
    var state: Factory

    private(set) var governedBy: CountryProperties?
    private(set) var occupiedBy: CountryProperties?

    private var productivity: Int64

    private(set) var workers: Workforce
    private(set) var clerks: Workforce?
    private(set) var equity: Equity<LegalEntity>.Statistics

    private(set) var cashFlow: CashFlowStatement

    private var budget: FactoryBudget?

    init(type: FactoryMetadata, state: Factory) {
        self.type = type
        self.state = state

        self.productivity = 0
        self.governedBy = nil
        self.occupiedBy = nil

        self.workers = .init()
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
        self.workers = .init()
        self.clerks = self.type.clerks == nil ? nil : .init()
    }

    mutating func addWorkforceCount(pop: Pop, job: FactoryJob) {
        if  case pop.type = self.type.workers.unit {
            self.workers.count(pop: pop.id, job: job)
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
    mutating func addPosition(asset: LegalEntity, value: Int64) {
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
        let area: Int64 = self.state.size.value
        self.workers.limit = self.type.workers.amount * area
        self.clerks?.limit = (self.type.clerks?.amount ?? 0) * area

        guard
        let tile: PlanetGrid.Tile = context.planets[self.state.on],
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

        self.equity = .compute(from: self.state.equity, in: context)
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

        /// Update the resource demands of this factory, returning the estimated marginal cost of
        /// input resources per worker-hour.
        ///
        /// This is a linear rate, and will slightly underestimate the true cost, due to the
        /// curvature of the market.
        let inputsCostPerHour: Double = self.state.today.ei * self.type.inputs.tradeable.reduce(
            into: 0
        ) {
            $0 += Double.init($1.value) * map.exchange.price(
                of: $1.key,
                in: country.currency.id
            )
        }

        // Compute input capacity. The stockpile target is computed relative to the number
        // of workers available, minus workers on strike. This prevents the factory from
        // spending all of its cash on inputs when there are not enough workers to process
        // them.
        self.state.ni.sync(
            with: self.type.inputs,
            scalingFactor: (self.productivity * self.workers.count, self.state.today.ei),
            stockpileDays: Self.stockpileDays.lowerBound,
        )

        self.state.nv.sync(
            with: self.type.costs,
            scalingFactor: (self.productivity * self.state.size.level, self.state.today.ei),
            stockpileDays: Self.stockpileDays.lowerBound,
        )

        let budget: FactoryBudget = self.budget(inputsCostPerHour: inputsCostPerHour)
        self.budget = budget
        self.state.today.px = Double.init(budget.px)

        guard
        let security: StockMarket<LegalEntity>.Security = .init(
            asset: .factory(self.state.id),
            price: budget.px
        ) else {
            return
        }

        map.stockMarkets.issueShares(security: security, currency: country.currency.id)
    }

    mutating func transact(map: inout GameMap) {
        guard
        let country: CountryProperties = self.occupiedBy,
        let budget: FactoryBudget = self.budget else {
            return
        }

        #assert(budget.workers >= 0, "Workers budget (\(budget.workers)) is negative?!?!")
        #assert(budget.clerks >= 0, "Clerks budget (\(budget.clerks)) is negative?!?!")
        #assert(budget.inputs >= 0, "Inputs budget (\(budget.inputs)) is negative?!?!")

        if  let (salaries, bonus): (Paychecks, Double) = self.clerkEffects(
                budget: budget.clerks,
                map: &map
            ) {
            self.state.today.eo = 1 + bonus
            self.state.today.cn = max(country.minwage, self.state.today.cn + salaries.change)
            self.state.today.ca = salaries.rate
            self.state.cash.c -= salaries.paid

            switch salaries.headcount {
            case nil:
                break
            case .fire(let block):
                map.jobs.fire.clerk[self.state.id] = block
            case .hire(let block, let type):
                map.jobs.hire.clerk[self.state.on.planet, type].append(block)
            }
        } else {
            self.state.today.eo = 1
        }

        let stockpileTarget: TradeableInput.StockpileTarget = .random(
            in: Self.stockpileDays,
            using: &map.random,
        )

        let wages: Paychecks = self.operate(
            policy: country,
            budget: budget,
            stockpileTarget: stockpileTarget,
            map: &map
        )

        let operatingProfit: Int64 = self.state.operatingProfit

        switch wages.headcount {
        case nil:
            break

        case .fire(let block):
            map.jobs.fire.worker[self.state.id] = block

        case .hire(let block, let type):
            guard operatingProfit >= 0 || self.workers.count == 0 else {
                break
            }

            map.jobs.hire.worker[self.state.on, type].append(block)
        }

        let investmentRatio: Fraction = (self.workers.count %/ (10 * self.workers.limit))
        let investmentBudget: Int64 = investmentRatio <> operatingProfit
        expansion:
        if  investmentBudget > 0 {
            let (gain, loss): (Int64, loss: Int64) = self.state.nv.trade(
                stockpileDays: stockpileTarget,
                spendingLimit: investmentBudget,
                in: country.currency.id,
                on: &map.exchange,
            )

            self.state.cash.v += loss
            self.state.cash.r += gain

            let growth: Int64 = self.state.nv.width(limit: 1, tier: self.type.costs)

            guard growth > 0 else {
                break expansion
            }

            self.state.size.grow()
            self.state.nv.consume(
                from: self.type.costs,
                scalingFactor: (self.productivity * self.state.size.level, self.state.today.ei)
            )
        }

        self.state.today.vv = self.state.nv.valueAcquired

        // Pay dividends to shareholders, if any.
        self.state.cash.i -= map.pay(
            dividend: budget.dividend,
            to: self.state.equity.shares.values.shuffled(using: &map.random.generator)
        )

        guard
        let security: StockMarket<LegalEntity>.Security = .init(
            asset: .factory(self.state.id),
            price: budget.px
        ) else {
            // Factory is bankrupt?
            return
        }

        if  self.state.size.level > 1 {
            self.state.cash.e -= map.buyback(
                value: budget.buybacks,
                from: &self.state.equity,
                of: security,
                in: country.currency.id
            )
        }
    }

    mutating func advance(map: inout GameMap) {
        guard
        let country: CountryProperties = self.occupiedBy else {
            return
        }

        // Add self.state subsidies at the end, after profit calculation.
        self.state.cash.s += self.state.size.value + country.minwage
        self.state.equity.split(price: self.state.today.px, map: &map, notifying: [country.id])
    }
}
extension FactoryContext {
    private mutating func operate(
        policy: CountryProperties,
        budget: FactoryBudget,
        stockpileTarget: TradeableInput.StockpileTarget,
        map: inout GameMap
    ) -> Paychecks {
        let (gain, loss): (Int64, loss: Int64) = self.state.ni.trade(
            stockpileDays: stockpileTarget,
            spendingLimit: budget.inputs,
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
            budget: budget.workers,
            map: &map
        )

        self.state.today.wn = max(policy.minwage, self.state.today.wn + wages.change)
        self.state.today.wa = wages.rate
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
    private func budget(
        inputsCostPerHour: Double
    ) -> FactoryBudget {
        let i: Double = self.state.today.ei * inputsCostPerHour * Double.init(
            self.productivity * self.workers.limit
        )

        let c: Double = self.clerks.map { Double.init(self.state.today.cn * $0.limit) } ?? 0
        let w: Double = Double.init(self.state.today.wn * self.workers.limit)

        let d: Fraction = 2 %/ 10_000

        let px: Fraction = self.equity.price(valuation: self.state.cash.balance)

        if  let budget: [Int64] = [i, c, w].distribute(self.state.cash.balance / 7) {
            let l: Int64 = .init((i + w).rounded(.up))

            let dividend: Int64 = self.state.cash.balance <> d
            let buybacks: Int64 = (self.state.cash.balance - l) / 365
            return FactoryBudget.init(
                inputs: budget[0],
                clerks: budget[1],
                workers: budget[2],
                dividend: dividend,
                buybacks: buybacks,
                px: px
            )
        }
        else {
            // All costs zero.
            return FactoryBudget.init(
                inputs: 0,
                clerks: 0,
                workers: 0,
                dividend: 0,
                buybacks: 0,
                px: px
            )
        }
    }

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
        let clerksOptimal: Int64 = self.workers.count >< clerkRatio

        let owed: Int64 = clerks.count * self.state.today.cn
        let paid: Int64 = map.pay(
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
            rate: clerks.count != 0
                ? Double.init(paid) / Double.init(clerks.count)
                : 0,
            headcount: headcount
        )

        // Compute clerk bonus in effect for today
        let bonus: Double = clerks.count < clerksOptimal
            ? Double.init(clerks.count) / Double.init(clerksOptimal)
            : 1

        return (salaries, bonus)
    }

    private func workerEffects(
        budget: Int64,
        map: inout GameMap
    ) -> (wages: Paychecks, hours: Int64) {
        /// Compute hours workable, assuming each worker works 1 “hour” per day for mathematical
        /// convenience. This can be larger than the actual number of workers available, but it
        /// will never be larger than the number of workers that can fit in the factory.
        let hoursWorkable: Int64 = self.state.ni.width(
            limit: self.workers.limit,
            tier: self.type.inputs
        )

        #assert(hoursWorkable >= 0, "Hours workable (\(hoursWorkable)) is negative?!?!")

        let hours: Int64 = min(
            min(self.workers.count, hoursWorkable),
            budget / self.state.today.wn
        )
        let paid: Int64 = hours <= 0 ? 0 : map.pay(
            wagesBudget: hours * self.state.today.wn,
            wages: map.payscale(shuffling: self.workers.pops, rate: self.state.today.wn)
        )

        let headcount: EmployeeOperations?
        let change: Int64

        if  hours < self.workers.count {
            // Not enough money to pay all workers, or not enough work to do.
            let layoff: FactoryJobLayoffBlock = .init(
                size: self.workers.count - hours
            )

            if  layoff.size > 0 {
                headcount = .fire(layoff)
            } else {
                headcount = nil
            }

            change = -1

        } else {
            let unspent: Int64 = budget - paid
            let open: Int64 = self.workers.limit - self.workers.count
            let hire: Int64 = min(open, unspent / self.state.today.wn)

            if  hire > 0 {
                if  self.workers.count < hire,
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
            rate: self.workers.count != 0
                ? Double.init(paid) / Double.init(self.workers.count)
                : 0,
            headcount: headcount
        )

        return (wages, hours)
    }
}
extension FactoryContext: LegalEntityContext {
    var equitySplits: [EquitySplit] { self.state.equity.splits }
}
