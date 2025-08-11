import Assert
import GameEconomy
import GameEngine
import GameRules
import JavaScriptKit
import JavaScriptInterop
import Random


struct PopContext {
    let type: PopMetadata
    var state: Pop

    private(set) var unemployment: Double
    private(set) var equity: Equity

    public init(type: PopMetadata, state: Pop) {
        self.type = type
        self.state = state

        self.unemployment = 0
        self.equity = .init()
    }
}
extension PopContext {
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
        country: Country,
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
                    $0[$1 != country.white] = +100%
                } = { "\(+$0[%]): Culture is not \(em: $1)" }
                $0[self.state.nat] {
                    $0[$1 == country.white] = -5%
                } = { "\(+$0[%]): Culture is \(em: $1)" }
            }
        }
    }

    func buildPromotionMatrix<Matrix>(
        country: Country,
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
                    $0[$1 != country.white] = -75%
                } = { "\(+$0[%]): Culture is not \(em: $1)" }
                $0[self.state.nat] {
                    $0[$1 == country.white] = +5%
                } = { "\(+$0[%]): Culture is \(em: $1)" }
            }

        }
    }
}
extension PopContext: RuntimeContext {
    mutating func compute(in context: GameContext.ResidentPass) throws {
        let unemployed: Int64 = self.state.unemployed
        self.unemployment = Double.init(unemployed) / Double.init(self.state.today.size)
    }

    mutating func advance(in context: GameContext, on map: inout GameMap) throws {
        guard
        let country: GameID<Country> = context.planets[self.state.home.planet]?.occupied,
        let country: Country = context.self.state.countries[country] else {
            return
        }

        self.state.today.size += Binomial[self.state.today.size, 0.000_02].sample(
            using: &map.random.generator
        )

        switch self.state.type.stratum {
        case .Ward:
            self.state.today.fl = 1
            self.state.today.fe = 1
            self.state.today.fx = 0

        default:
            let w: (l: Double, e: Double, x: Double) = self.state.needsPerCapita
            let stockpileDays: Int64 = 3
            let stockpileTarget: Int64 = map.random.int64(in: stockpileDays ... 7)

            self.state.nl.sync(with: self.type.l) {
                $0.sync(
                    coefficient: $1,
                    multiplier: self.state.today.size,
                    stockpile: stockpileDays,
                    efficiency: w.l
                )
            }
            self.state.ne.sync(with: self.type.e) {
                $0.sync(
                    coefficient: $1,
                    multiplier: self.state.today.size,
                    stockpile: stockpileDays,
                    efficiency: w.e
                )
            }
            self.state.nx.sync(with: self.type.x) {
                $0.sync(
                    coefficient: $1,
                    multiplier: self.state.today.size,
                    stockpile: stockpileDays,
                    efficiency: w.x
                )
            }

            /// Pops will target 30 days of savings for their needs.
            var budget: Int64 = self.state.cash.balance / 30
            if  budget > 0 {
                let spent: Int64 = self.state.nl.buy(
                    days: stockpileTarget,
                    with: budget,
                    in: country.currency.id,
                    on: &map.exchange,
                )

                self.state.cash.b -= spent
            }

            self.state.today.fl = self.state.nl.reduce(1) { min($0, $1.fulfilled) }
            self.state.nl.sync(with: self.type.l) {
                budget -= $0.consume($1.amount * self.state.today.size, efficiency: w.l)
            }

            if budget > 0 {
                let spent: Int64 = self.state.ne.buy(
                    days: stockpileTarget,
                    with: budget,
                    in: country.currency.id,
                    on: &map.exchange,
                )

                self.state.cash.b -= spent
            }

            self.state.today.fe = self.state.ne.reduce(1) { min($0, $1.fulfilled) }
            self.state.ne.sync(with: self.type.e) {
                budget -= $0.consume($1.amount * self.state.today.size, efficiency: w.e)
            }

            if budget > 0 {
                let spent: Int64 = self.state.nx.buy(
                    days: stockpileTarget,
                    with: budget,
                    in: country.currency.id,
                    on: &map.exchange,
                )
                self.state.cash.b -= spent
            }

            self.state.today.fx = self.state.nx.reduce(1) { min($0, $1.fulfilled) }
            self.state.nx.sync(with: self.type.x) {
                budget -= $0.consume($1.amount * self.state.today.size, efficiency: w.x)
            }
        }

        self.state.out.sync(with: self.type.output) {
            $0.deposit($1.amount * self.state.today.size, efficiency: 1)
        }
        // This comes at the end, mostly because worker and clerk pops don’t get paid until
        // after the turn is over, and we want all payments to happen at the same logical stage.
        self.state.cash.r += self.state.out.sell(in: country.currency.id, on: &map.exchange)
        switch self.state.type.stratum {
        case .Ward:
            // Pay dividends to shareholders, if any.
            self.state.cash.i -= map.pay(
                dividend: self.state.cash.balance,
                to: self.equity.owners.shuffled(using: &map.random.generator)
            )

        default:
            self.state.cash.s += self.state.today.size * country.minwage / 10
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
                guard let factory: Factory = context.state.factories[$0.at] else {
                    // Factory has gone bankrupt or been destroyed.
                    $0.fireAll()
                    return
                }

                let wn: Double
                let wu: Double

                if self.state.type.stratum <= .Worker {
                    wn = factory.yesterday.wna
                    wu = factory.yesterday.wua
                } else {
                    wn = factory.yesterday.caa
                    wu = factory.yesterday.caa
                }

                /// At this rate, if the factory pays minimum wage or less, about half of
                /// non-union workers, and one third of union workers, will quit every year.
                $0.quit(
                    nonunionRate: 0.002 * w0 / max(w0, wn),
                    unionRate: 0.001 * w0 / max(w0, wu),
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
                    let quit: Int64 = min(nonexistent, $0.n + $0.u)
                    $0.quit(quit)
                    nonexistent -= quit
                } (&self.state.jobs.values[i])
            }
        }
    }
}
