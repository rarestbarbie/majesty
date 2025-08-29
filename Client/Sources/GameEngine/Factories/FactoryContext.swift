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

    init(type: FactoryMetadata, state: Factory) {
        self.type = type
        self.state = state

        self.productivity = 0
        self.policy = nil

        self.workers = .init()
        self.clerks = nil
        self.equity = .init()

        self.cashFlow = .init()
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
extension FactoryContext {
    private mutating func budget(
        in currency: Fiat,
        on exchange: borrowing Exchange
    ) -> FactoryBudget {
        var inputsCostPerHour: Double = 0

        self.state.ni.sync(with: self.type.inputs) {
            inputsCostPerHour += Double.init($1.amount) * exchange.price(
                of: $0.id,
                in: currency
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

        let i: Double = self.state.today.ei * inputsCostPerHour * Double.init(
            self.productivity * self.workers.limit
        )

        let c: Double = self.clerks.map { Double.init(self.state.today.cn * $0.limit) } ?? 0
        let w: Double = Double.init(self.state.today.wn * self.workers.limit)


        if  let budget: [Int64] = [i, c, w].distribute(self.state.cash.balance) {
            return FactoryBudget.init(inputs: budget[0], clerks: budget[1], workers: budget[2])
        }
        else {
            // All costs zero.
            return FactoryBudget.init(inputs: 0, clerks: 0, workers: 0)
        }
    }

    private mutating func produce(budget: FactoryBudget, on map: inout GameMap) -> Int64 {
        /// Compute hours workable, assuming each worker works 1 “hour” per day for mathematical
        /// convenience. This can be larger than the actual number of workers available, but it
        /// will never be larger than the number of workers that can fit in the factory.
        let hoursWorkable: Int64 = zip(self.state.ni, self.type.inputs).reduce(
            self.workers.limit
        ) {
            let (resource, input) : (ResourceInput, Quantity<Resource>) = $1
            return min($0, resource.acquired / input.amount)
        }

        #assert(hoursWorkable >= 0, "Hours workable (\(hoursWorkable)) is negative?!?!")

        guard hoursWorkable > 0 else {
            return 0
        }

        // Compute the number of hours that can be worked by union workers, limited by the
        // funds available to pay them.
        let hoursWorked: Int64 = min(
            min(self.workers.count, hoursWorkable),
            budget.workers / self.state.today.wn
        )
        let wagesPaid: Int64 = map.pay(
            wagesBudget: hoursWorked * self.state.today.wn,
            wages: map.payscale(shuffling: self.workers.pops, rate: self.state.today.wn)
        )

        self.state.cash.w -= wagesPaid
        self.state.today.wa = self.workers.count != 0
            ? Double.init(wagesPaid) / Double.init(self.workers.count)
            : 0

        /// On some days, the factory purchases more inputs than others. To get a more accurate
        /// estimate of the factory’s profitability, we need to credit the day’s balance with
        /// the amount of currency that was sunk into purchasing inputs, and subtract the
        /// approximate value of the inputs consumed today.
        self.state.ni.sync(with: self.type.inputs) {
            $0.consume(
                self.productivity * $1.amount * hoursWorked,
                efficiency: self.state.today.ei
            )
        }
        self.state.out.sync(with: self.type.output) {
            $0.deposit(
                self.productivity * $1.amount * hoursWorked,
                efficiency: self.state.today.eo
            )
        }

        return hoursWorked
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
        self.cashFlow.update(with: self.state.ni)
        self.cashFlow[.workers] = -self.state.cash.w
        self.cashFlow[.clerks] = -self.state.cash.c
    }

    mutating func advance(in context: GameContext, on map: inout GameMap) throws {
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

        /// Compute budget item ratios
        let budget: FactoryBudget = self.budget(in: country.currency, on: map.exchange)

        #assert(budget.workers >= 0, "Workers budget (\(budget.workers)) is negative?!?!")
        #assert(budget.clerks >= 0, "Clerks budget (\(budget.clerks)) is negative?!?!")
        #assert(budget.inputs >= 0, "Inputs budget (\(budget.inputs)) is negative?!?!")

        if  let clerks: Workforce = self.clerks,
            let clerkTeam: Quantity<PopType> = self.type.clerks {

            let clerkRatio: Fraction = clerkTeam.amount %/ self.type.workers.amount
            let clerksOptimal: Int64 = self.workers.count >< clerkRatio

            // Compute clerk bonus in effect for today
            self.state.today.eo = clerks.count < clerksOptimal
                ? 1 + Double.init(clerks.count) / Double.init(clerksOptimal)
                : 2

            let salariesOwed: Int64 = clerks.count * self.state.today.cn
            let salariesPaid: Int64 = map.pay(
                salariesBudget: budget.clerks,
                salaries: [
                    map.payscale(shuffling: clerks.pops, rate: self.state.today.cn),
                ]
            )

            self.state.cash.c -= salariesPaid
            self.state.today.ca = clerks.count != 0
                ? Double.init(salariesPaid) / Double.init(clerks.count)
                : 0

            let salariesUnspent: Int64 = budget.clerks - salariesPaid

            if  salariesPaid < salariesOwed {
                // Not enough money to pay all clerks.
                if  self.state.today.cn > country.minwage {
                    self.state.today.cn -= 1
                }

                let retention: Fraction = salariesPaid %/ salariesOwed
                let retained: Int64 = clerks.count <> retention

                let layoff: FactoryJobLayoffBlock = .init(
                    size: clerks.count - retained
                )

                if  layoff.size > 0 {
                    map.jobs.fire.clerk[self.state.id] = layoff
                }
            } else {
                let clerksAffordable: Int64 = salariesUnspent / self.state.today.cn
                let clerksNeeded: Int64 = clerksOptimal - clerks.count
                let clerksToHire: Int64 = min(clerksNeeded, clerksAffordable)

                if  clerks.count < clerksNeeded,
                    let p: Int = self.state.yesterday.cf,
                    map.random.roll(Int64.init(p), Int64.init(Self.pr)) {
                    // Was last in line to hire clerks yesterday, did not hire any clerks, and has
                    // fewer than half of the target number of clerks today.
                    self.state.today.cn += 1
                }

                let bid: FactoryJobOfferBlock = .init(
                    at: self.state.id,
                    bid: self.state.today.cn,
                    size: Binomial[clerksToHire, 0.05].sample(using: &map.random.generator)
                )

                if  bid.size > 0 {
                    map.jobs.hire.clerk[self.state.on.planet, clerkTeam.unit].append(bid)
                }
            }
        }

        let stockpileTarget: Int64 = map.random.int64(in: Self.stockpileDays ... 7)
        let inputSpend: Int64 = self.state.ni.buy(
            days: stockpileTarget,
            with: budget.inputs,
            in: country.currency,
            on: &map.exchange,
        )

        self.state.cash.b -= inputSpend

        #assert(self.state.cash.balance >= 0, "Factory has negative cash! (\(self.state.cash))")

        let hoursWorked: Int64 = self.produce(budget: budget, on: &map)
        // Sell outputs.
        self.state.cash.r += self.state.out.sell(in: country.currency, on: &map.exchange)

        #assert(self.state.cash.balance >= 0, "Factory has negative cash! (\(self.state.cash))")

        self.state.today.fi = self.state.ni.reduce(1) { min($0, $1.fulfilled) }
        self.state.today.vi = self.state.ni.reduce(0) { $0 + $1.acquiredValue }

        let profit: Int64 = self.state.cash.change + self.state.Δ.vi

        recruitment:
        if  hoursWorked < self.workers.count {
            // Not enough money to pay all workers, or not enough work to do.
            if  self.state.today.wn > country.minwage {
                self.state.today.wn -= 1
            }

            let layoff: FactoryJobLayoffBlock = .init(
                size: self.workers.count - hoursWorked
            )

            if  layoff.size > 0 {
                map.jobs.fire.worker[self.state.id] = layoff
            }
        } else if profit >= 0 {
            let wagesUnspent: Int64 = budget.workers + self.state.cash.w
            let filled: Int64 = self.workers.count // Includes workers on strike
            let open: Int64 = self.workers.limit - filled
            let hire: Int64 = min(open, wagesUnspent / self.state.today.wn)

            if  hire <= 0 {
                break recruitment
            }

            if  filled < hire,
                let p: Int = self.state.yesterday.wf,
                map.random.roll(Int64.init(p), Int64.init(Self.pr)) {
                // Was last in line to hire workers yesterday, did not hire any workers, and has
                // far more inputs stockpiled than workers to process them.
                self.state.today.wn += 1
            }

            let bid: FactoryJobOfferBlock = .init(
                at: self.state.id,
                bid: self.state.today.wn,
                size: Binomial[hire, 0.1].sample(using: &map.random.generator)
            )

            if  bid.size > 0 {
                map.jobs.hire.worker[self.state.on, self.type.workers.unit].append(bid)
            }
        }


        self.state.nv.sync(with: self.type.costs) {
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

            let growth: Int64 = zip(self.state.nv, self.type.costs).reduce(1) {
                let (resource, input) : (ResourceInput, Quantity<Resource>) = $1
                return min($0, resource.acquired / input.amount)
            }

            guard growth > 0 else {
                break expansion
            }

            self.state.grow += growth
            self.state.nv.sync(with: self.type.costs) {
                $0.consume($1.amount * self.productivity, efficiency: self.state.today.ei)
            }

            if  self.state.grow >= 100 {
                self.state.size += 1
                self.state.grow = 0
            }
        }

        self.state.today.vv = self.state.nv.reduce(0) { $0 + $1.acquiredValue }

        // Pay dividends to shareholders, if any.
        self.state.cash.i -= map.pay(
            dividend: self.state.cash.balance <> (2 %/ 10_000),
            to: self.equity.owners.shuffled(using: &map.random.generator)
        )

        // Add self.state subsidies at the end, after profit calculation.
        self.state.cash.s += self.state.size
    }
}
