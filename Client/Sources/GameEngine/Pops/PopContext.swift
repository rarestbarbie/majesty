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
        self.cashFlow.update(with: self.state.nl.tradeable.values.elements)
        self.cashFlow.update(with: self.state.nl.inelastic.values.elements)
        self.cashFlow.update(with: self.state.ne.tradeable.values.elements)
        self.cashFlow.update(with: self.state.ne.inelastic.values.elements)
        self.cashFlow.update(with: self.state.nx.tradeable.values.elements)
        self.cashFlow.update(with: self.state.nx.inelastic.values.elements)

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

        /// Compute vertical weights.
        let z: (l: Double, e: Double, x: Double) = self.state.needsPerCapita

        self.state.nl.sync(
            with: self.type.l,
            scalingFactor: (self.state.today.size, z.l),
            stockpileDays: Self.stockpileDays,
        )
        self.state.ne.sync(
            with: self.type.e,
            scalingFactor: (self.state.today.size, z.e),
            stockpileDays: Self.stockpileDays,
        )
        self.state.nx.sync(
            with: self.type.x,
            scalingFactor: (self.state.today.size, z.x),
            stockpileDays: Self.stockpileDays,
        )
        self.state.out.sync(
            with: self.type.output,
            scalingFactor: (self.state.today.size, 1)
        )

        /// Compute horizontal weights.
        let weights: (
            l: (tradeable: TradeableBudgetTier, inelastic: InelasticBudgetTier),
            e: (tradeable: TradeableBudgetTier, inelastic: InelasticBudgetTier),
            x: (tradeable: TradeableBudgetTier, inelastic: InelasticBudgetTier)
        )

        weights.l.tradeable = .compute(
            demands: self.state.nl.tradeable,
            markets: map.exchange,
            currency: currency,
        )
        weights.e.tradeable = .compute(
            demands: self.state.ne.tradeable,
            markets: map.exchange,
            currency: currency,
        )
        weights.x.tradeable = .compute(
            demands: self.state.nx.tradeable,
            markets: map.exchange,
            currency: currency,
        )

        weights.l.inelastic = .compute(
            demands: self.state.nl.inelastic,
            markets: map.localMarkets,
            location: self.state.home,
        )
        weights.e.inelastic = .compute(
            demands: self.state.ne.inelastic,
            markets: map.localMarkets,
            location: self.state.home,
        )
        weights.x.inelastic = .compute(
            demands: self.state.nx.inelastic,
            markets: map.localMarkets,
            location: self.state.home,
        )

        var budget: PopBudget = .init()

        let inelasticCostPerDay: (l: Int64, e: Int64, x: Int64) = (
            l: weights.l.inelastic.total,
            e: weights.e.inelastic.total,
            x: weights.x.inelastic.total,
        )
        let tradeableCostPerDay: (l: Int64, e: Int64, x: Int64) = (
            l: Int64.init(weights.l.tradeable.total.rounded(.up)),
            e: Int64.init(weights.e.tradeable.total.rounded(.up)),
            x: Int64.init(weights.x.tradeable.total.rounded(.up)),
        )
        let totalCostPerDay: (l: Int64, e: Int64) = (
            l: tradeableCostPerDay.l + inelasticCostPerDay.l,
            e: tradeableCostPerDay.e + inelasticCostPerDay.e,
        )

        let d: (l: Int64, e: Int64, x: Int64) = (7, 30, 365)
        /// These are the minimum theoretical balances the pop would need to purchase 100% of
        /// its needs in that tier on any particular day.
        let min: (l: Int64, e: Int64) = (
            l: totalCostPerDay.l * d.l,
            e: totalCostPerDay.e * d.e,
        )

        budget.l.distribute(
            funds: self.state.cash.balance / d.l,
            inelastic: inelasticCostPerDay.l * Self.stockpileMax,
            tradeable: tradeableCostPerDay.l * Self.stockpileMax,
        )

        budget.e.distribute(
            funds: (self.state.cash.balance - min.l) / d.e,
            inelastic: inelasticCostPerDay.e * Self.stockpileMax,
            tradeable: tradeableCostPerDay.e * Self.stockpileMax,
        )

        budget.x.distribute(
            funds: (self.state.cash.balance - min.l - min.e) / d.x,
            inelastic: inelasticCostPerDay.x * Self.stockpileMax,
            tradeable: tradeableCostPerDay.x * Self.stockpileMax,
        )

        for (budget, weights, tier):
            (Int64, [InelasticBudgetTier.Weight], ResourceTierIdentifier) in [
            (budget.l.inelastic, weights.l.inelastic.x, .l),
            (budget.e.inelastic, weights.e.inelastic.x, .e),
            (budget.x.inelastic, weights.x.inelastic.x, .x),
        ] {
            guard budget > 0,
            let allocations: [Int64] = weights.distribute(budget, share: \.value) else {
                continue
            }
            for (allocation, x): (Int64, InelasticBudgetTier.Weight) in zip(
                allocations,
                weights
            ) where allocation > 0 {
                map.localMarkets[self.state.home, x.id].bid(
                    budget: allocation,
                    by: self.state.id,
                    in: tier,
                    limit: x.units
                )
            }
        }

        for (id, output): (Resource, InelasticOutput) in self.state.out.inelastic {
            let ask: Int64 = output.unitsProduced
            if  ask > 0 {
                map.localMarkets[self.state.home, id].ask(amount: ask, by: self.state.id)
            }
        }

        self.budget = budget
    }
}
extension PopContext {
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
        in tier: ResourceTierIdentifier?
    ) {
        guard let tier: ResourceTierIdentifier else {
            return
        }

        let value: Int64 = units * price

        switch tier {
        case .l:
            self.state.nl.inelastic[resource]?.report(
                unitsConsumed: units,
                valueConsumed: value,
            )
        case .e:
            self.state.ne.inelastic[resource]?.report(
                unitsConsumed: units,
                valueConsumed: value,
            )
        case .x:
            self.state.nx.inelastic[resource]?.report(
                unitsConsumed: units,
                valueConsumed: value,
            )

        case _:
            return
        }

        self.state.cash.b -= value
    }
}
extension PopContext {
    mutating func transact(on map: inout GameMap) {
        guard
        let country: CountryPolicies = self.policy else {
            return
        }

        self.state.out.deposit(
            from: self.type.output,
            scalingFactor: (self.state.today.size, 1)
        )

        self.state.cash.r += self.state.out.sell(
            in: country.currency,
            on: &map.exchange
        )

        if  let budget: PopBudget = self.budget {
            let target: ClosedRange<Int64> = Self.stockpileDays ... map.random.int64(
                in: Self.stockpileDays ... Self.stockpileMax
            )
            let z: (l: Double, e: Double, x: Double) = self.state.needsPerCapita

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
            self.state.nl.consume(
                from: self.type.l,
                scalingFactor: (self.state.today.size, z.l)
            )

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
            self.state.ne.consume(
                from: self.type.e,
                scalingFactor: (self.state.today.size, z.e)
            )

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
            self.state.nx.consume(
                from: self.type.x,
                scalingFactor: (self.state.today.size, z.x)
            )

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
