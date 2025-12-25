import Assert
import Fraction
import GameEconomy
import GameIDs
import GameRules
import GameState
import OrderedCollections
import Random

struct FactoryContext: LegalEntityContext, RuntimeContext {
    let type: FactoryMetadata
    var state: Factory

    private(set) var region: RegionalAuthority?

    private(set) var productivity: Int64

    private(set) var workers: Workforce?
    private(set) var clerks: Workforce?
    private(set) var equity: Equity<LEI>.Statistics
    private(set) var cashFlow: CashFlowStatement

    init(type: FactoryMetadata, state: Factory) {
        self.type = type
        self.state = state

        self.productivity = 0
        self.region = nil

        self.workers = nil
        self.clerks = nil
        self.equity = .init()
        self.cashFlow = .init()
    }
}
extension FactoryContext: Identifiable {
    var id: FactoryID { self.state.id }
}
extension FactoryContext {
    private static var stockpileDays: ClosedRange<Int64> { 3 ... 7 }

    static var efficiencyBonusFromCorporate: Double { 0.3 }
    static var efficiencyBonusFromClerks: Double { 0.3 }

    static func efficiencyBonusFromCorporate(fe: Double) -> Double {
        Self.efficiencyBonusFromCorporate * .sqrt(fe)
    }
    static func efficiencyBonusFromClerks(fk: Double) -> Double {
        Self.efficiencyBonusFromClerks * .sqrt(fk)
    }

    static var pr: Int { 8 }

    var snapshot: FactorySnapshot? {
        guard let region: RegionalAuthority = self.region else {
            return nil
        }
        return .init(
            type: self.type,
            state: self.state,
            region: region.properties,
            productivity: self.productivity,
            workers: self.workers,
            clerks: self.clerks,
            equity: self.equity,
            cashFlow: self.cashFlow
        )
    }
}
extension FactoryContext {
    mutating func startIndexCount() {
        if self.state.size.level == 0 {
            self.workers = nil
            self.clerks = nil
        } else {
            self.workers = .empty
            self.clerks = .empty
        }
    }

    mutating func addWorkforceCount(pop: Pop, job: FactoryJob) {
        if  self.type.workers.unit == pop.occupation {
            self.workers?.count(pop: pop.id, job: job)
        } else if
            self.type.clerks.unit == pop.occupation {
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
    mutating func afterIndexCount(
        world _: borrowing GameWorld,
        context: ComputationPass
    ) throws {
        if  let area: Int64 = self.state.size.area {
            self.workers?.limit = area * self.type.workers.amount
            self.clerks?.limit = area * self.type.clerks.amount
        }

        self.region = context.planets[self.state.tile]?.authority

        guard
        let region: RegionalProperties = self.region?.properties else {
            return
        }

        self.productivity = region.modifiers.factoryProductivity[self.state.type]?.value ?? 1

        self.cashFlow.reset()
        self.cashFlow.update(with: self.state.inventory.l)
        self.cashFlow.update(with: self.state.inventory.e)
        self.cashFlow[.workers] = self.state.spending.wages
        self.cashFlow[.clerks] = self.state.spending.salaries
    }
}
extension FactoryContext: TransactingContext {
    mutating func allocate(turn: inout Turn) {
        guard
        let region: RegionalProperties = self.region?.properties else {
            return
        }

        // Align wages with the national minimum wage.
        self.state.z.wn = max(self.state.z.wn, region.minwage)
        self.state.z.cn = max(self.state.z.cn, region.minwage)

        #assert(
            0 ... 1 ~= self.state.y.fe,
            "Factory input efficiency out of bounds! (\(self.state.y.fe))"
        )
        // Input efficiency, bonus from paying clerks and buying all corporate needs yesterday
        if  self.state.size.level == 0 {
            self.state.z.ei = 1
        } else {
            self.state.z.ei = 1
                - Self.efficiencyBonusFromCorporate(fe: self.state.y.fe)
                - Self.efficiencyBonusFromClerks(fk: self.state.y.fk)
        }

        // Reset fill positions, since they are copied from yesterday’s positions by default.
        self.state.z.wf = nil
        self.state.z.cf = nil

        let throughput: Int64 = self.workers.map {
            self.productivity * min($0.limit, $0.count + 1)
        } ?? 0

        self.state.inventory.out.sync(with: self.type.output, releasing: 1 %/ 4)
        self.state.inventory.l.sync(
            with: self.type.materials,
            scalingFactor: (throughput, self.state.z.ei),
        )
        self.state.inventory.e.sync(
            with: self.type.corporate,
            scalingFactor: (throughput, self.state.z.ei),
        )
        self.state.inventory.x.sync(
            with: self.type.expansion,
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
            self.state.budget = .liquidating(
                account: turn.bank[account: self.lei],
                sharePrice: self.equity.sharePrice
            )
            return
        }

        let weights: (segmented: SegmentedWeights<InelasticDemand>, tradeable: AggregateWeights)
        let budget: OperatingBudget
        let sharesToIssue: Int64

        if  let workers: Workforce = self.workers,
            let clerks: Workforce = self.clerks {
            #assert(workers.limit > 0, "active factory has zero worker limit?!?!")
            let utilization: Double = min(1, Double.init(workers.count %/ workers.limit))

            weights.segmented = .business(
                l: self.state.inventory.l,
                e: self.state.inventory.e,
                x: self.state.inventory.x,
                markets: turn.localMarkets,
                address: self.state.tile,
            )
            weights.tradeable = .business(
                l: self.state.inventory.l,
                e: self.state.inventory.e,
                x: self.state.inventory.x,
                markets: turn.worldMarkets,
                currency: region.currency.id,
            )

            budget = .factory(
                account: turn.bank[account: self.lei],
                weights: weights,
                state: self.state.z,
                type: self.type,
                stockpileMaxDays: Self.stockpileDays.upperBound,
                workers: workers,
                clerks: clerks,
                invest: utilization * max(0, self.state.z.profitability),
                d: .business,
            )

            let sharesTarget: Int64 = self.state.size.level * self.type.sharesPerLevel
                + self.type.sharesInitial
            let sharesIssued: Int64 = max(0, sharesTarget - self.equity.shareCount)

            sharesToIssue = budget.buybacks == 0 ? sharesIssued : 0

            self.state.budget = .active(budget)
        } else {
            #assert(self.state.size.level == 0, "factory with no workers has `level > 0`?!")

            weights.segmented = .businessNew(
                x: self.state.inventory.x,
                markets: turn.localMarkets,
                address: self.state.tile,
            )
            weights.tradeable = .businessNew(
                x: self.state.inventory.x,
                markets: turn.worldMarkets,
                currency: region.currency.id,
            )

            budget = .factory(
                account: turn.bank[account: self.lei],
                weights: weights,
                state: self.state.z,
                type: self.type,
                stockpileMaxDays: Self.stockpileDays.upperBound,
                workers: nil,
                clerks: nil,
                invest: 1,
                d: .businessNew,
            )
            sharesToIssue = max(0, self.type.sharesInitial - self.equity.shareCount)

            self.state.budget = .constructing(budget)
        }

        // only issue shares if the factory is not performing buybacks
        // but this needs to be called even if quantity is zero, or the security will not
        // be tradeable today
        turn.stockMarkets.issueShares(
            currency: region.currency.id,
            quantity: sharesToIssue,
            security: self.security,
        )

        turn.localMarkets.tradeAsBusiness(
            selling: self.state.inventory.out.segmented,
            buying: weights.segmented,
            budget: (
                budget.l.segmented,
                budget.e.segmented,
                budget.x.segmented
            ),
            as: self.lei,
            in: self.state.tile
        )
    }

    mutating func transact(turn: inout Turn) {
        guard
        let region: RegionalProperties = self.region?.properties,
        let budget: Factory.Budget = self.state.budget else {
            return
        }

        let stockpileTarget: ResourceStockpileTarget = .random(
            in: Self.stockpileDays,
            using: &turn.random,
        )

        switch budget {
        case .constructing(let budget):
            self.state.z.profitability = 1
            self.construct(
                region: region,
                budget: budget.l,
                stockpileTarget: stockpileTarget,
                turn: &turn
            )

        case .liquidating(let budget):
            self.liquidate(region: region, budget: budget, turn: &turn)

            self.state.z.profitability = -1
            self.state.spending.buybacks += turn.bank.buyback(
                security: self.security,
                budget: budget.buybacks,
                equity: &self.state.equity,
                random: &turn.random,
            )

        case .active(let budget):
            #assert(budget.workers >= 0, "Workers budget (\(budget.workers)) is negative?!?!")
            #assert(budget.clerks >= 0, "Clerks budget (\(budget.clerks)) is negative?!?!")

            #assert(self.state.size.level > 0, "Active factory has size level 0?!?!")

            let fireToday: (clerks: Int64, workers: Int64)
            let fireLater: (clerks: Int64, workers: Int64)

            let hireToday: (clerks: Int64, workers: Int64)
            let hireLater: (clerks: Int64, workers: Int64)

            let profit: ProfitMargins

            if  let workers: Workforce = self.workers,
                let clerks: Workforce = self.clerks {
                let office: OfficeUpdate = .operate(
                    factory: self.state,
                    type: self.type,
                    workers: workers,
                    clerks: clerks,
                    budget: budget,
                    turn: &turn
                )

                self.state.spending.salariesUsed += office.salariesPaid - office.salariesIdle
                self.state.spending.salariesIdle += office.salariesIdle

                self.state.z.fk = office.fk

                fireToday.clerks = office.fireToday
                fireLater.clerks = office.fireLater
                hireToday.clerks = office.hireToday
                hireLater.clerks = office.hireLater

                let floor: FloorUpdate = self.operate(
                    workers: workers,
                    region: region,
                    budget: budget,
                    stockpileTarget: stockpileTarget,
                    turn: &turn
                )

                // this is expensive to compute, so do it only once
                profit = self.state.profit

                if  workers.count > 0, profit.contribution < 0 {
                    let fire: Int64
                    if  workers.count == 1, self.clerks?.count ?? 0 == 0 {
                        // the other branch would never fire the last worker
                        if  turn.random.roll(1, profit.gross < 0 ? 7 : 30) {
                            fire = 1
                        } else {
                            fire = 0
                        }
                    } else {
                        /// Fire up to 40% of workers based on marginal profitability.
                        /// If gross profit is also negative, this happens more quickly.
                        let l: Double = max(0, -0.4 * profit.marginalProfitability)
                        let firable: Int64 = .init(l * Double.init(workers.count))
                        if  firable > 0, profit.gross < 0 || turn.random.roll(1, 3) {
                            fire = .random(in: 0 ... firable, using: &turn.random.generator)
                        } else {
                            fire = 0
                        }
                    }

                    let fireExpedited: Int64 = max(0, fire - floor.fireToday)
                    fireToday.workers = floor.fireToday + fireExpedited
                    fireLater.workers = max(0, floor.fireLater - fireExpedited)

                    hireToday.workers = 0
                    hireLater.workers = 0
                } else {
                    fireToday.workers = floor.fireToday
                    fireLater.workers = floor.fireLater

                    hireToday.workers = floor.hireToday
                    hireLater.workers = floor.hireLater
                }
            } else {
                self.state.z.fk = 0

                fireToday.clerks = 0
                fireLater.clerks = 0
                hireToday.clerks = 0
                hireLater.clerks = 0

                fireToday.workers = 0
                fireLater.workers = 0
                hireToday.workers = 0
                hireLater.workers = 0

                profit = self.state.profit
            }

            let fire: (clerks: Int64, workers: Int64)

            if  fireLater.clerks > 0, turn.random.roll(1, 21) {
                fire.clerks = fireToday.clerks + fireLater.clerks
            } else {
                fire.clerks = fireToday.clerks
            }

            if  fireLater.workers > 0, turn.random.roll(1, 7) {
                fire.workers = fireToday.workers + fireLater.workers
            } else {
                fire.workers = fireToday.workers
            }

            if  let clerks: Workforce = self.clerks {
                if  let fire: PopJobLayoffBlock = .init(size: fire.clerks) {
                    turn.jobs.fire[self.state.id, self.type.clerks.unit] = fire
                    // clerk salaries are not sticky, but will never fall below worker wage
                    self.state.z.cn = max(self.state.z.wn, self.state.z.cn - 1)
                } else if hireToday.clerks > 0 {
                    //  raise wages if
                    //  -   tried and failed to hire employees yesterday
                    //  -   current number of employees is less than number of employees we are
                    //      looking to hire
                    //  -   position in line was far enough back that the reason for not hiring
                    //      was probably low wages
                    if  let p: Int = self.state.y.cf,
                        clerks.count < hireToday.clerks + hireLater.clerks,
                        turn.random.roll(Int64.init(p), Int64.init(FactoryContext.pr)) {
                        self.state.z.cn += 1
                    }

                    let market: PlanetaryMarket = .init(
                        planet: self.state.tile.planet,
                        medium: region.currency.id
                    )
                    let hire: PopJobOfferBlock = .init(
                        job: .factory(self.state.id),
                        bid: self.state.z.cn,
                        size: hireToday.clerks
                    )
                    turn.jobs.hire.remote[market, self.type.clerks.unit].append(hire)
                }
            }

            if  let workers: Workforce = self.workers {
                if  let fire: PopJobLayoffBlock = .init(size: fire.workers) {
                    turn.jobs.fire[self.state.id, self.type.workers.unit] = fire
                } else if hireToday.workers > 0 {
                    // see above
                    if  let p: Int = self.state.y.wf,
                        workers.count < hireToday.workers + hireLater.workers,
                        turn.random.roll(Int64.init(p), Int64.init(FactoryContext.pr)) {
                        self.state.z.wn += 1
                    }

                    let hire: PopJobOfferBlock = .init(
                        job: .factory(self.state.id),
                        bid: self.state.z.wn,
                        size: hireToday.workers
                    )
                    turn.jobs.hire.local[self.state.tile, self.type.workers.unit].append(hire)
                }
            }

            self.construct(
                region: region,
                budget: budget.x,
                stockpileTarget: stockpileTarget,
                turn: &turn
            )

            self.state.spending.buybacks += turn.bank.buyback(
                security: self.security,
                budget: budget.buybacks,
                equity: &self.state.equity,
                random: &turn.random,
            )
            // Pay dividends to shareholders, if any.
            self.state.spending.dividend += turn.bank.transfer(
                budget: budget.dividend,
                source: self.lei,
                recipients: self.state.equity.shares.values.shuffled(
                    using: &turn.random.generator
                )
            )

            self.state.z.mix(profitability: profit.marginalProfitability)
        }
    }

    mutating func advance(turn: inout Turn) {
        self.state.z.vl = self.state.inventory.l.valueAcquired
        self.state.z.ve = self.state.inventory.e.valueAcquired
        self.state.z.vx = self.state.inventory.x.valueAcquired

        guard case nil = self.state.liquidation,
        let player: CountryID = self.region?.occupiedBy else {
            return
        }

        if  self.workers?.count ?? 0 == 0,
            self.clerks?.count ?? 0 == 0,
            self.state.y.profitability <= 0,
            self.state.z.profitability <= 0 {
            self.state.liquidation = .init(started: turn.date, burning: self.equity.shareCount)
        } else {
            self.state.equity.split(
                price: self.state.z.px,
                turn: &turn,
                notifying: [player]
            )
        }
    }
}
extension FactoryContext {
    private mutating func construct(
        region: RegionalProperties,
        budget: ResourceBudgetTier,
        stockpileTarget: ResourceStockpileTarget,
        turn: inout Turn
    ) {
        if  budget.tradeable > 0 {
            {
                $0 += self.state.inventory.x.tradeAsBusiness(
                    stockpileDays: stockpileTarget,
                    spendingLimit: budget.tradeable,
                    in: region.currency.id,
                    on: &turn.worldMarkets,
                )
            } (&turn.bank[account: self.lei])
        }

        let growthFactor: Int64 = self.productivity * (self.state.size.level + 1)
        if  self.state.inventory.x.consumeAvailable(
                from: self.type.expansion,
                scalingFactor: (growthFactor, self.state.z.ei)
            ) {
            self.state.size.grow()
        }

        self.state.z.fx = self.state.inventory.x.fulfilled
    }

    private mutating func liquidate(
        region: RegionalProperties,
        budget: LiquidationBudget,
        turn: inout Turn
    ) {
        {
            let stockpileNone: ResourceStockpileTarget = .init(lower: 0, today: 0, upper: 0)
            let tl: TradeProceeds = self.state.inventory.l.tradeAsBusiness(
                stockpileDays: stockpileNone,
                spendingLimit: 0,
                in: region.currency.id,
                on: &turn.worldMarkets,
            )
            let te: TradeProceeds = self.state.inventory.e.tradeAsBusiness(
                stockpileDays: stockpileNone,
                spendingLimit: 0,
                in: region.currency.id,
                on: &turn.worldMarkets,
            )
            let tx: TradeProceeds = self.state.inventory.x.tradeAsBusiness(
                stockpileDays: stockpileNone,
                spendingLimit: 0,
                in: region.currency.id,
                on: &turn.worldMarkets,
            )

            #assert(tl.loss == 0, "nl loss during liquidation is non-zero! (\(tl.loss))")
            #assert(te.loss == 0, "ne loss during liquidation is non-zero! (\(te.loss))")
            #assert(tx.loss == 0, "nx loss during liquidation is non-zero! (\(tx.loss))")

            let proceeds: Int64 = tl.gain + te.gain + tx.gain
            $0.r += proceeds
        } (&turn.bank[account: self.lei])
    }

    private mutating func operate(
        workers: Workforce,
        region: RegionalProperties,
        budget: OperatingBudget,
        stockpileTarget: ResourceStockpileTarget,
        turn: inout Turn
    ) -> FloorUpdate {
        {
            if  budget.l.tradeable > 0 {
                $0 += self.state.inventory.l.tradeAsBusiness(
                    stockpileDays: stockpileTarget,
                    spendingLimit: budget.l.tradeable,
                    in: region.currency.id,
                    on: &turn.worldMarkets,
                )
            }
            if  budget.e.tradeable > 0 {
                $0 += self.state.inventory.e.tradeAsBusiness(
                    stockpileDays: stockpileTarget,
                    spendingLimit: budget.e.tradeable,
                    in: region.currency.id,
                    on: &turn.worldMarkets,
                )
            }

            #assert(
                $0.balance >= 0,
                """
                Factory (id = \(self.id), type = '\(self.type.symbol)') \
                has negative cash! (\($0))
                """
            )

            $0.r += self.state.inventory.out.sell(
                in: region.currency.id,
                on: &turn.worldMarkets
            )
        } (&turn.bank[account: self.lei])

        let update: FloorUpdate = .operate(
            factory: self.state,
            type: self.type,
            workers: workers,
            budget: budget.workers,
            turn: &turn
        )

        self.state.spending.wages += update.wagesPaid

        /// On some days, the factory purchases more inputs than others. To get a more accurate
        /// estimate of the factory’s profitability, we need to credit the day’s balance with
        /// the amount of currency that was sunk into purchasing inputs, and subtract the
        /// approximate value of the inputs consumed today.
        let throughput: Int64 = self.productivity * update.workersPaid
        self.state.inventory.l.consumeAmortized(
            from: self.type.materials,
            scalingFactor: (throughput, self.state.z.ei)
        )
        self.state.inventory.e.consumeAmortized(
            from: self.type.corporate,
            scalingFactor: (throughput, self.state.z.ei * budget.fe)
        )

        self.state.inventory.out.deposit(
            from: self.type.output,
            scalingFactor: (throughput, self.state.z.eo)
        )

        self.state.z.fl = self.state.inventory.l.fulfilled
        // `fulfilled` counts stockpiled resources that were saved for the next day,
        // so to compute the actual usage today we need `min` it with the consumption fraction
        self.state.z.fe = min(self.state.inventory.e.fulfilled, budget.fe)

        return update
    }
}
