import Assert
import D
import GameConditions
import GameEconomy
import GameRules
import GameState
import JavaScriptKit
import JavaScriptInterop
import Random

struct PopContext {
    let type: PopMetadata
    var state: Pop

    private(set) var policy: CountryPolicies?

    private(set) var unemployment: Double
    private(set) var equity: Equity

    private(set) var cashFlow: CashFlowStatement

    private var budget: PopBudget?

    public init(type: PopMetadata, state: Pop) {
        self.type = type
        self.state = state

        self.policy = nil

        self.unemployment = 0
        self.equity = .init()
        self.cashFlow = .init()

        self.budget = nil
    }
}
extension PopContext {
    private static var stockpileDays: Int64 { 3 }
    private static var stockpileMax: Int64 { 7 }

    mutating func startIndexCount() {
        self.equity = .init()
    }

    mutating func addShareholderCount(pop: Pop, shares: Int64) {
        #assert(
            shares > 0,
            "Pop (id = \(pop.id)) owns \(shares) shares of pop '\(self.type.plural)'!"
        )

        self.equity.count(pop: pop.id, shares: shares)
    }
}

extension PopContext {
    func buildDemotionMatrix<Matrix>(
        country: CountryPolicies,
        type: Matrix.Type = Matrix.self,
    ) -> Matrix where Matrix: ConditionMatrix<Decimal, Double> {
        .init(base: 0%) {
            $0[self.unemployment] {
                $0[$1 >= 0.1] = +2‱
                $0[$1 >= 0.2] = +1‱
                $0[$1 >= 0.3] = +1‱
            } = { "\(+$0[%]): Unemployment is above \(em: $1[%0])" }

            $0[self.state.yesterday.fl] {
                $0[$1 < 1.00] = +1‰
                $0[$1 < 0.75] = +5‰
                $0[$1 < 0.50] = +2‰
                $0[$1 < 0.25] = +2‰
            } = { "\(+$0[%]): Getting less than \(em: $1[%0]) of Life Needs" }

        } factors: {
            $0[self.state.yesterday.fx] {
                $0[$1 > 0.25] = -90%
            } = { "\(+$0[%]): Getting more than \(em: $1[%0]) of Luxury Needs" }

            $0[self.state.yesterday.mil] {
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

            switch self.state.type.stratum {
            case .Ward:
                $0[true] {
                    $0 = -100%
                } = { "\(+$0[%]): Pop is \(em: "enslaved")" }

            default:
                $0[self.state.nat] {
                    $0[$1 != country.culture] = +100%
                } = { "\(+$0[%]): Culture is not \(em: $1)" }
                $0[self.state.nat] {
                    $0[$1 == country.culture] = -5%
                } = { "\(+$0[%]): Culture is \(em: $1)" }
            }
        }
    }

    func buildPromotionMatrix<Matrix>(
        country: CountryPolicies,
        type: Matrix.Type = Matrix.self,
    ) -> Matrix where Matrix: ConditionMatrix<Decimal, Double> {
        .init(base: 0%) {
            $0[self.state.yesterday.fe] {
                $0[$1 >= 0.75] = +2‰
            } = { "\(+$0[%]): Getting more than \(em: $1[%0]) of Everyday Needs" }
            $0[self.state.yesterday.fx] {
                $0[$1 >= 0.25] = +3‰
                $0[$1 >= 0.50] = +3‰
                $0[$1 >= 0.75] = +3‰
            } = { "\(+$0[%]): Getting more than \(em: $1[%0]) of Luxury Needs" }

            $0[self.state.yesterday.mil] {
                $0[$1 >= 5.0] = -1‰
                $0[$1 >= 7.0] = -1‰
                $0[$1 >= 9.0] = -1‰
            } = { "\(+$0[%]): Militancy is above \(em: $1[..1])" }

            $0[self.state.yesterday.con] {
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
            $0[self.state.yesterday.fl] {
                $0[$1 < 1.00] = -100%
            } = { "\(+$0[%]): Getting less than \(em: $1[%0]) of Life Needs" }

            $0[self.state.yesterday.mil] {
                $0[$1 >= 2.0] = -20%
                $0[$1 >= 4.0] = -10%
                $0[$1 >= 6.0] = -10%
                $0[$1 >= 8.0] = -10%
            } = { "\(+$0[%]): Militancy is above \(em: $1[..1])" }

            switch self.state.type.stratum {
            case .Ward:
                $0[true] {
                    $0 = -100%
                } = { "\(+$0[%]): Pop is \(em: "enslaved")" }

            default:
                $0[self.state.nat] {
                    $0[$1 != country.culture] = -75%
                } = { "\(+$0[%]): Culture is not \(em: $1)" }
                $0[self.state.nat] {
                    $0[$1 == country.culture] = +5%
                } = { "\(+$0[%]): Culture is \(em: $1)" }
            }

        }
    }
}
extension PopContext: RuntimeContext {
    mutating func compute(in context: GameContext.ResidentPass) throws {
        guard
        let country: CountryID = context.planets[self.state.home.planet]?.occupied,
        let country: Country = context.countries.state[country] else {
            return
        }

        let unemployed: Int64 = self.state.unemployed
        self.unemployment = Double.init(unemployed) / Double.init(self.state.today.size)

        self.cashFlow.reset()
        self.cashFlow.update(with: self.state.nl.tradeable)
        self.cashFlow.update(with: self.state.ne.tradeable)
        self.cashFlow.update(with: self.state.nx.tradeable)

        self.policy = country.policies
    }
}
extension PopContext: TransactingContext {
    mutating func allocate(on map: inout GameMap) {
        self.state.today.size += Binomial[self.state.today.size, 0.000_02].sample(
            using: &map.random.generator
        )

        if  case .Ward = self.state.type.stratum {
            return
        }

        let currency: Fiat = self.policy!.currency
        /// Compute weights of inelastic demands, since we place bids at the same time we
        /// compute the budget, instead of recalculating weights at the time of transaction.
        let weights: (
            l: [(Resource, weight: Int64)],
            e: [(Resource, weight: Int64)],
            x: [(Resource, weight: Int64)]
        ) = (
            l: self.type.l.inelastic.map {
                ($0, map.localMarkets[self.state.home, $0].yesterday.price * $1)
            },
            e: self.type.e.inelastic.map {
                ($0, map.localMarkets[self.state.home, $0].yesterday.price * $1)
            },
            x: self.type.x.inelastic.map {
                ($0, map.localMarkets[self.state.home, $0].yesterday.price * $1)
            }
        )

        var basePerCapita: (tradeable: Tiers, inelastic: Tiers) = (
            tradeable: .init(),
            inelastic: .init(
                l: Double.init(weights.l.reduce(0) { $0 + $1.weight }),
                e: Double.init(weights.e.reduce(0) { $0 + $1.weight }),
                x: Double.init(weights.x.reduce(0) { $0 + $1.weight }),
            )
        )
        let w: Tiers = self.state.needsPerCapita

        self.state.nl.tradeable.sync(with: self.type.l.tradeable) {
            basePerCapita.tradeable.l += Double.init($1.amount) * map.exchange.price(
                of: $0.id,
                in: currency
            )
            $0.sync(
                coefficient: $1,
                multiplier: self.state.today.size,
                stockpile: Self.stockpileDays,
                efficiency: w.l
            )
        }
        self.state.ne.tradeable.sync(with: self.type.e.tradeable) {
            basePerCapita.tradeable.e += Double.init($1.amount) * map.exchange.price(
                of: $0.id,
                in: currency
            )
            $0.sync(
                coefficient: $1,
                multiplier: self.state.today.size,
                stockpile: Self.stockpileDays,
                efficiency: w.e
            )
        }
        self.state.nx.tradeable.sync(with: self.type.x.tradeable) {
            basePerCapita.tradeable.x += Double.init($1.amount) * map.exchange.price(
                of: $0.id,
                in: currency
            )
            $0.sync(
                coefficient: $1,
                multiplier: self.state.today.size,
                stockpile: Self.stockpileDays,
                efficiency: w.x
            )
        }

        let scaleDaily: Double = .init(self.state.today.size)
        let scaleMax: Double = .init(self.state.today.size * Self.stockpileMax)

        let costPerCapita: (tradeable: Tiers, inelastic: Tiers, total: Tiers) = (
            tradeable: w * basePerCapita.tradeable,
            inelastic: w * basePerCapita.inelastic,
            total: w * (basePerCapita.tradeable + basePerCapita.inelastic)
        )
        let costPerPeriod: (tradeable: Tiers, inelastic: Tiers) = (
            tradeable: costPerCapita.tradeable * scaleMax,
            inelastic: costPerCapita.inelastic * scaleMax
        )

        var budget: PopBudget = .init()

        let costPerDay: (l: Double, e: Double) = (
            l: scaleDaily * costPerCapita.total.l,
            e: scaleDaily * costPerCapita.total.e
        )

        _ = budget.l.distribute(
            funds: self.state.cash.balance / 7,
            inelastic: Int64.init(costPerPeriod.inelastic.l.rounded(.up)),
            tradeable: Int64.init(costPerPeriod.tradeable.l.rounded(.up)),
        )

        _ = budget.e.distribute(
            funds: self.state.cash.balance / 30 - Int64.init(costPerDay.l.rounded(.up)),
            inelastic: Int64.init(costPerPeriod.inelastic.e.rounded(.up)),
            tradeable: Int64.init(costPerPeriod.tradeable.e.rounded(.up)),
        )

        _ = budget.x.distribute(
            funds: self.state.cash.balance / 365 - Int64.init(
                (costPerDay.l + costPerDay.e).rounded(.up)
            ),
            inelastic: Int64.init(costPerPeriod.inelastic.x.rounded(.up)),
            tradeable: Int64.init(costPerPeriod.tradeable.x.rounded(.up)),
        )

        for (budget, weights): (Int64, [(Resource, weight: Int64)]) in [
            (budget.l.inelastic, weights.l),
            (budget.e.inelastic, weights.e),
            (budget.x.inelastic, weights.x),
        ] {
            guard budget > 0,
            let bids: [Int64] = weights.distribute(budget, share: \.weight) else {
                continue
            }
            for ((id, _), bid): ((Resource, _), Int64) in zip(weights, bids) where bid > 0 {
                map.localMarkets[self.state.home, id].bid(bid, by: self.state.id)
            }
        }

        for (id, amount): (Resource, Int64) in self.type.output.inelastic {
            map.localMarkets[self.state.home, id].ask(
                amount * self.state.today.size,
                by: self.state.id
            )
        }

        self.budget = budget
    }
}
extension PopContext {
    mutating func transact(on map: inout GameMap) {
        guard
        let country: CountryPolicies = self.policy else {
            return
        }

        self.state.out.tradeable.sync(with: self.type.output.tradeable) {
            $0.deposit($1.amount * self.state.today.size, efficiency: 1)
        }

        self.state.cash.r += self.state.out.sell(
            in: country.currency,
            on: &map.exchange
        )

        if  let budget: PopBudget = self.budget {
            let target: Int64 = map.random.int64(in: Self.stockpileDays ... Self.stockpileMax)
            let w: Tiers = self.state.needsPerCapita

            if  budget.l.tradeable > 0 {
                let spent: Int64 = self.state.nl.buy(
                    days: target,
                    with: budget.l.tradeable,
                    in: country.currency,
                    on: &map.exchange,
                )

                self.state.cash.b -= spent
            }

            self.state.today.fl = self.state.nl.fulfilled
            self.state.nl.tradeable.sync(with: self.type.l.tradeable) {
                $0.consume($1.amount * self.state.today.size, efficiency: w.l)
            }

            if  budget.e.tradeable > 0 {
                let spent: Int64 = self.state.ne.buy(
                    days: target,
                    with: budget.e.tradeable,
                    in: country.currency,
                    on: &map.exchange,
                )

                self.state.cash.b -= spent
            }

            self.state.today.fe = self.state.ne.fulfilled
            self.state.ne.tradeable.sync(with: self.type.e.tradeable) {
                $0.consume($1.amount * self.state.today.size, efficiency: w.e)
            }

            if  budget.x.tradeable > 0 {
                let spent: Int64 = self.state.nx.buy(
                    days: target,
                    with: budget.x.tradeable,
                    in: country.currency,
                    on: &map.exchange,
                )
                self.state.cash.b -= spent
            }

            self.state.today.fx = self.state.nx.fulfilled
            self.state.nx.tradeable.sync(with: self.type.x.tradeable) {
                $0.consume($1.amount * self.state.today.size, efficiency: w.x)
            }

            // Welfare
            self.state.cash.s += self.state.today.size * country.minwage / 10
        } else {
            // Pop is enslaved
            self.state.today.fl = 1
            self.state.today.fe = 1
            self.state.today.fx = 0

            // Pay dividends to shareholders, if any.
            self.state.cash.i -= map.pay(
                dividend: self.state.cash.balance,
                to: self.equity.owners.shuffled(using: &map.random.generator)
            )
        }
    }

    mutating func advance(factories: RuntimeStateTable<FactoryContext>, on map: inout GameMap) {
        guard
        let country: CountryPolicies = self.policy else {
            return
        }

        self.state.today.mil += 0.020 * (1.0 - self.state.today.fl)
        self.state.today.mil += 0.004 * (0.5 - self.state.today.fe)
        self.state.today.mil += 0.004 * (0.0 - self.state.today.fx)

        self.state.today.con += 0.010 * (self.state.today.fl - 1.0)
        self.state.today.con += 0.002 * (1.0 - self.state.today.fe)
        self.state.today.con += 0.020 * (self.state.today.fx - 0.0)

        self.state.today.mil = max(0, min(10, self.state.today.mil))
        self.state.today.con = max(0, min(10, self.state.today.con))

        if self.state.type.stratum > .Ward {
            self.state.egress(
                evaluator: self.buildDemotionMatrix(country: country),
                direction: >=,
                on: &map,
            )
            self.state.egress(
                evaluator: self.buildPromotionMatrix(country: country),
                direction: <=,
                on: &map
            )
        }

        // We do not need to remove jobs that have no employees left, that will be done
        // automatically by ``Pop.turn``.
        let jobs: Range<Int> = self.state.jobs.values.indices
        let w0: Double = .init(country.minwage)
        for i: Int in jobs {
            {
                guard let factory: Factory = factories[$0.at] else {
                    // Factory has gone bankrupt or been destroyed.
                    $0.fireAll()
                    return
                }

                let earned: Double

                if self.state.type.stratum <= .Worker {
                    earned = factory.yesterday.wa
                } else {
                    earned = factory.yesterday.ca
                }

                /// At this rate, if the factory pays minimum wage or less, about half of
                /// non-union workers, and one third of union workers, will quit every year.
                $0.quit(
                    rate: 0.002 * w0 / max(w0, earned),
                    using: &map.random.generator
                )
            } (&self.state.jobs.values[i])
        }

        let unemployed: Int64 = self.state.unemployed
        if  unemployed < 0 {
            /// We have negative unemployment! This happens when the popuation shrinks, either
            /// through pop death or conversion.
            var nonexistent: Int64 = -unemployed
            /// This algorithm will probably generate more indices than we need. Alternatively,
            /// we could draw indices on demand, but that would have very pathological
            /// performance in the rare case that we have many empty jobs that have not yet
            /// been linted.
            for i: Int in jobs.shuffled(using: &map.random.generator) {
                guard 0 < nonexistent else {
                    break
                }

                {
                    let quit: Int64 = min(nonexistent, $0.count)
                    $0.quit(quit)
                    nonexistent -= quit
                } (&self.state.jobs.values[i])
            }
        }
    }
}
