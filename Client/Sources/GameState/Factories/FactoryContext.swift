import Assert
import GameEconomy
import GameEngine
import GameRules
import JavaScriptKit
import JavaScriptInterop
import OrderedCollections
import Random

struct FactoryContext {
    let type: FactoryMetadata
    var state: Factory

    private var productivity: Int64

    private(set) var workers: Workforce
    private(set) var clerks: Workforce
    private(set) var equity: Equity

    init(type: FactoryMetadata, state: Factory) {
        self.type = type
        self.state = state

        self.productivity = 0
        self.workers = .init()
        self.clerks = .init()
        self.equity = .init()
    }
}
extension FactoryContext {
    private static var stockpileDays: Int64 { 7 }
    static var pr: Int { 8 }

    mutating func startIndexCount() {
        self.workers = .init()
        self.clerks = .init()
        self.equity = .init()
    }

    mutating func addWorkforceCount(pop: Pop, job: FactoryJob) {
        switch pop.type {
        case self.type.workers.unit:
            self.workers.count(pop: pop.id, job: job)

        case self.type.clerks.unit:
            self.clerks.count(pop: pop.id, job: job)

        default:
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
        self.clerks.limit = self.type.clerks.amount * self.state.size

        guard
        let country: GameID<Country> = pass.planets[self.state.on]?.occupied,
        let modifiers: FactoryModifiers = pass.countries[country]?.factories else {
            return
        }

        self.productivity = modifiers.productivity[self.state.type]
    }

    mutating func advance(in context: GameContext, on map: inout GameMap) throws {
        guard
        let country: GameID<Country> = context.planets[self.state.on]?.occupied,
        let country: Country = context.state.countries[country] else {
            return
        }

        let stockpileDays: Int64 = 3
        let stockpileTarget: Int64 = map.random.int64(in: stockpileDays ... 7)

        // Align wages with the national minimum wage.
        self.state.today.wn = max(self.state.today.wn, country.minwage)
        self.state.today.wu = max(self.state.today.wu, country.minwage)
        self.state.today.cn = max(self.state.today.cn, country.minwage)
        self.state.today.cu = max(self.state.today.cu, country.minwage)

        /// Use 1/3 of current balance to pay clerk salaries, 1/3 to buy inputs for today,
        /// and set aside the rest for worker wages. Pay clerks salaries first, in case there
        /// are leftover funds, which will be evenly split between inputs and worker wages.
        let salariesBudget: Int64 = self.state.cash.balance / 3
        let salariesOwed: Int64 =
            self.clerks.u.count * self.state.today.cu +
            self.clerks.n.count * self.state.today.cn

        let salariesPaid: Int64 = map.pay(
            salariesBudget: salariesBudget,
            salaries: [
                map.payscale(shuffling: clerks.u.pops, rate: self.state.today.cu),
                map.payscale(shuffling: clerks.n.pops, rate: self.state.today.cn),
            ]
        )

        self.state.cash.c -= salariesPaid
        self.state.today.caa = self.clerks.present != 0
            ? Double.init(salariesPaid) / Double.init(self.clerks.present)
            : 0

        // Compute input capacities. The stockpile target is computed relative to the number of
        // workers available, minus workers on strike. This prevents the factory from spending
        // all of its cash on inputs when there are not enough workers to process them.
        self.state.ni.sync(with: self.type.inputs) {
            $0.sync(
                coefficient: $1,
                multiplier: self.productivity * self.workers.present,
                stockpile: stockpileDays,
            )
        }
        let wagesBudget: Int64 = self.state.cash.balance / 2
        let inputBudget: Int64 = self.state.cash.balance - wagesBudget

        #assert(wagesBudget >= 0, "Wages budget (\(wagesBudget)) is negative?!?!")

        let inputSpend: Int64 = self.state.ni.buy(
            days: stockpileTarget,
            with: inputBudget,
            in: country.currency.id,
            on: &map.exchange,
        )

        self.state.cash.b -= inputSpend

        #assert(self.state.cash.balance >= 0, "Factory has negative cash! (\(self.state.cash))")

        self.state.today.fi = self.state.ni.reduce(1) { min($0, $1.fulfilled) }

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

        let hoursWorked: (u: Int64, n: Int64, total: Int64)
        let wagesPaid: (u: Int64, n: Int64)

        // Compute the number of hours that can be worked by union workers, limited by the
        // funds available to pay them.
        hoursWorked.u = min(
            min(self.workers.u.count, hoursWorkable),
            self.state.cash.balance / self.state.today.wu
        )

        wagesPaid.u = map.pay(
            wagesBudget: hoursWorked.u * self.state.today.wu,
            wages: map.payscale(shuffling: self.workers.u.pops, rate: self.state.today.wu)
        )

        self.state.cash.w -= wagesPaid.u
        self.state.today.wua = self.workers.u.count != 0
            ? Double.init(wagesPaid.u) / Double.init(self.workers.u.count)
            : 0

        // Compute the number of hours that can be worked by non-union workers, if there is
        // work available for them and funds to pay them.
        hoursWorked.n = min(
            min(self.workers.n.count, hoursWorkable - hoursWorked.u),
            self.state.cash.balance / self.state.today.wn
        )

        wagesPaid.n = map.pay(
            wagesBudget: hoursWorked.n * self.state.today.wn,
            wages: map.payscale(shuffling: self.workers.n.pops, rate: self.state.today.wn)
        )

        self.state.cash.w -= wagesPaid.n
        self.state.today.wna = self.workers.n.count != 0
            ? Double.init(wagesPaid.n) / Double.init(self.workers.n.count)
            : 0

        hoursWorked.total = hoursWorked.u + hoursWorked.n

        /// This is the optimal number of clerks for the number of workers that worked today.
        /// The clerk bonus is capped at 2x.
        let (clerksOptimal, _): (quotient: Int64, Int64) = self.workers.limit.dividingFullWidth(
            hoursWorked.total.multipliedFullWidth(by: self.clerks.limit)
        )
        let clerksBonus: Double = self.clerks.present < clerksOptimal
            ? 1 + Double.init(self.clerks.present) / Double.init(clerksOptimal)
            : 2

        self.state.today.ei = 1
        self.state.today.eo = clerksBonus

        /// On some days, the factory purchases more inputs than others. To get a more accurate
        /// estimate of the factory’s profitability, we need to credit the day’s balance with
        /// the amount of currency that was sunk into purchasing inputs, and subtract the
        /// approximate value of the inputs consumed today.
        self.state.ni.sync(with: self.type.inputs) {
            $0.consume(
                self.productivity * $1.amount * hoursWorked.total,
                efficiency: self.state.today.ei
            )
        }
        self.state.out.sync(with: self.type.output) {
            $0.deposit(
                self.productivity * $1.amount * hoursWorked.total,
                efficiency: self.state.today.eo
            )
        }

        // Sell outputs.
        self.state.cash.r += self.state.out.sell(in: country.currency.id, on: &map.exchange)

        #assert(self.state.cash.balance >= 0, "Factory has negative cash! (\(self.state.cash))")

        // Reset fill positions, since they are copied from yesterday’s positions by default.
        self.state.today.wf = nil
        self.state.today.cf = nil

        self.state.today.vi = self.state.ni.reduce(0) { $0 + $1.acquiredValue }
        let profit: Int64 = self.state.cash.change + self.state.Δ.vi

        recruitment:
        if  hoursWorked.total < self.workers.present {
            // Not enough money to pay all workers, or not enough work to do.
            if  self.state.today.wn > country.minwage {
                self.state.today.wn -= 1
            }
        } else if profit >= 0 {
            let wagesUnspent: Int64 = wagesBudget + self.state.cash.w
            let filled: Int64 = self.workers.total // Includes workers on strike
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
                self.state.today.wu = max(self.state.today.wu, self.state.today.wn)
            }

            let bid: FactoryJobOfferBlock = .init(
                at: self.state.id,
                bid: self.state.today.wn,
                size: Binomial[hire, 0.1].sample(using: &map.random.generator)
            )

            if  bid.size > 0 {
                map.jobs[self.state.on, self.type.workers.unit].append(bid)
            }
        }

        recruitment:
        if  salariesPaid < salariesOwed {
            // Not enough money to pay all clerks.
            if  self.state.today.cn > country.minwage {
                self.state.today.cn -= 1
            }
        } else if profit >= 0 {
            let salariesUnspent: Int64 = salariesBudget + self.state.cash.c
            let positions: Int64 = min(self.clerks.limit, clerksOptimal)
            let filled: Int64 = self.clerks.total
            let open: Int64 = positions - filled
            let hire: Int64 = min(open, salariesUnspent / self.state.today.cn)

            if  hire <= 0 {
                break recruitment
            }

            if  filled < hire,
                let p: Int = self.state.yesterday.cf,
                map.random.roll(Int64.init(p), Int64.init(Self.pr)) {
                // Was last in line to hire clerks yesterday, did not hire any clerks, and has
                // fewer than half of the target number of clerks today.
                self.state.today.cn += 1
                self.state.today.cu = max(self.state.today.cu, self.state.today.cn)
            }

            let bid: FactoryJobOfferBlock = .init(
                at: self.state.id,
                bid: self.state.today.cn,
                size: Binomial[hire, 0.05].sample(using: &map.random.generator)
            )

            if  bid.size > 0 {
                map.jobs[self.state.on, self.type.clerks.unit].append(bid)
            }
        }

        self.state.nv.sync(with: self.type.costs) {
            $0.sync(
                coefficient: $1,
                multiplier: self.productivity,
                stockpile: stockpileDays,
            )
        }

        let investmentRatio: Fraction = (self.workers.total %/ (10 * self.workers.limit))
        let investmentBudget: Int64 = investmentRatio *> profit
        expansion:
        if  investmentBudget > 0 {
            self.state.cash.v -= self.state.nv.buy(
                days: stockpileTarget,
                with: investmentBudget,
                in: country.currency.id,
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
            dividend: self.state.cash.balance *> (2 %/ 10_000),
            to: self.equity.owners.shuffled(using: &map.random.generator)
        )

        // Add self.state subsidies at the end, after profit calculation.
        self.state.cash.s += self.state.size
    }
}
