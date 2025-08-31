import Assert
import GameEconomy
import GameRules
import GameState
import JavaScriptKit
import JavaScriptInterop
import OrderedCollections
import Random

struct FactoryContext {
    let type: FactoryMetadata
    var state: Factory

    private(set) var policy: CountryPolicies?

    private var productivity: Int64

    private(set) var workers: Workforce
    private(set) var clerks: Workforce?
    private(set) var equity: Equity

    private(set) var cashFlow: CashFlowStatement

    private var budget: FactoryBudget?

    init(type: FactoryMetadata, state: Factory) {
        self.type = type
        self.state = state

        self.productivity = 0
        self.policy = nil

        self.workers = .init()
        self.clerks = nil
        self.equity = .init()

        self.cashFlow = .init()

        self.budget = nil
    }
}
extension FactoryContext {
    private static var stockpileDays: Int64 { 3 }
    static var pr: Int { 8 }

    mutating func startIndexCount() {
        self.workers = .init()
        self.clerks = self.type.clerks == nil ? nil : .init()
        self.equity = .init()
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
    mutating func addShareholderCount(pop: Pop, shares: Int64) {
        #assert(
            shares > 0,
            "Pop (id = \(pop.id)) owns \(shares) shares of factory '\(self.type.name)'!"
        )

        self.equity.count(pop: pop.id, shares: shares)
    }
}
extension FactoryContext: RuntimeContext {
    mutating func compute(in pass: GameContext.ResidentPass) throws {
        self.workers.limit = self.type.workers.amount * self.state.size
        self.clerks?.limit = (self.type.clerks?.amount ?? 0) * self.state.size

        guard
        let country: CountryID = pass.planets[self.state.on.planet]?.occupied,
        let country: CountryContext = pass.countries[country] else {
            return
        }

        self.productivity = country.factories.productivity[self.state.type]
        self.policy = country.state.policies

        self.cashFlow.reset()
        self.cashFlow.update(with: self.state.ni.tradeable)
        self.cashFlow[.workers] = -self.state.cash.w
        self.cashFlow[.clerks] = -self.state.cash.c
    }
}
extension FactoryContext: TransactingContext {
    mutating func allocate(on map: inout GameMap) {
        guard
        let country: CountryPolicies = self.policy else {
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
        var inputsCostPerHour: Double = 0

        self.state.ni.tradeable.sync(with: self.type.inputs.tradeable) {
            inputsCostPerHour += Double.init($1.amount) * map.exchange.price(
                of: $0.id,
                in: country.currency
            )
            // Compute input capacity. The stockpile target is computed relative to the number
            // of workers available, minus workers on strike. This prevents the factory from
            // spending all of its cash on inputs when there are not enough workers to process
            // them.
            $0.sync(
                coefficient: $1,
                multiplier: self.productivity * self.workers.count,
                stockpile: Self.stockpileDays,
            )
        }

        self.budget = self.budget(inputsCostPerHour: inputsCostPerHour)
    }

    mutating func transact(on map: inout GameMap) {
        guard
        let country: CountryPolicies = self.policy,
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

        let stockpileTarget: Int64 = map.random.int64(in: Self.stockpileDays ... 7)
        let profit: Int64

        do {
            let inputSpend: Int64 = self.state.ni.buy(
                days: stockpileTarget,
                with: budget.inputs,
                in: country.currency,
                on: &map.exchange,
            )

            self.state.cash.b -= inputSpend

            #assert(
                self.state.cash.balance >= 0,
                "Factory has negative cash! (\(self.state.cash))"
            )

            let (wages, hours): (Paychecks, Int64) = self.workerEffects(
                budget: budget.workers,
                map: &map
            )

            self.state.today.wn = max(country.minwage, self.state.today.wn + wages.change)
            self.state.today.wa = wages.rate
            self.state.cash.w -= wages.paid

            /// On some days, the factory purchases more inputs than others. To get a more accurate
            /// estimate of the factory’s profitability, we need to credit the day’s balance with
            /// the amount of currency that was sunk into purchasing inputs, and subtract the
            /// approximate value of the inputs consumed today.
            self.state.ni.tradeable.sync(with: self.type.inputs.tradeable) {
                $0.consume(
                    self.productivity * $1.amount * hours,
                    efficiency: self.state.today.ei
                )
            }
            self.state.out.tradeable.sync(with: self.type.output.tradeable) {
                $0.deposit(
                    self.productivity * $1.amount * hours,
                    efficiency: self.state.today.eo
                )
            }

            // Sell outputs.
            self.state.cash.r += self.state.out.sell(in: country.currency, on: &map.exchange)

            #assert(self.state.cash.balance >= 0, "Factory has negative cash! (\(self.state.cash))")

            self.state.today.fi = self.state.ni.fulfilled
            self.state.today.vi = self.state.ni.valuation

            profit = self.state.cash.change + self.state.Δ.vi

            switch wages.headcount {
            case nil:
                break

            case .fire(let block):
                map.jobs.fire.worker[self.state.id] = block

            case .hire(let block, let type):
                guard profit >= 0 else {
                    break
                }

                map.jobs.hire.worker[self.state.on, type].append(block)
            }
        }

        self.state.nv.tradeable.sync(with: self.type.costs.tradeable) {
            $0.sync(
                coefficient: $1,
                multiplier: self.productivity,
                stockpile: Self.stockpileDays,
            )
        }

        let investmentRatio: Fraction = (self.workers.count %/ (10 * self.workers.limit))
        let investmentBudget: Int64 = investmentRatio <> profit
        expansion:
        if  investmentBudget > 0 {
            self.state.cash.v -= self.state.nv.buy(
                days: stockpileTarget,
                with: investmentBudget,
                in: country.currency,
                on: &map.exchange,
            )

            let growth: Int64 = self.state.nv.width(limit: 1, tier: self.type.costs)

            guard growth > 0 else {
                break expansion
            }

            self.state.grow += growth
            self.state.nv.tradeable.sync(with: self.type.costs.tradeable) {
                $0.consume($1.amount * self.productivity, efficiency: self.state.today.ei)
            }

            if  self.state.grow >= 100 {
                self.state.size += 1
                self.state.grow = 0
            }
        }

        self.state.today.vv = self.state.nv.valuation

        // Pay dividends to shareholders, if any.
        self.state.cash.i -= map.pay(
            dividend: self.state.cash.balance <> (2 %/ 10_000),
            to: self.equity.owners.shuffled(using: &map.random.generator)
        )
    }

    mutating func advance() {
        // Add self.state subsidies at the end, after profit calculation.
        self.state.cash.s += self.state.size
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


        if  let budget: [Int64] = [i, c, w].distribute(self.state.cash.balance / 7) {
            return FactoryBudget.init(inputs: budget[0], clerks: budget[1], workers: budget[2])
        }
        else {
            // All costs zero.
            return FactoryBudget.init(inputs: 0, clerks: 0, workers: 0)
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
