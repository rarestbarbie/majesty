import Assert
import D
import GameEconomy
import GameRules
import GameState
import GameIDs
import GameUI
import Random

struct BuildingContext: LegalEntityContext, RuntimeContext {
    let type: BuildingMetadata
    var state: Building
    private(set) var stats: Building.Stats

    private(set) var region: RegionalProperties?
    private(set) var equity: Equity<LEI>.Statistics

    init(type: BuildingMetadata, state: Building) {
        self.type = type
        self.state = state
        self.stats = .init()

        self.region = nil
        self.equity = .init()
    }
}
extension BuildingContext: Identifiable {
    var id: BuildingID { self.state.id }
}
extension BuildingContext {
    typealias ComputationPass = FactoryContext.ComputationPass
    private static var stockpileDays: ClosedRange<Int64> { 3 ... 7 }
}
extension BuildingContext {
    mutating func startIndexCount() {
        self.stats.update(from: self.state)
    }
    mutating func addPosition(asset: LEI, value: Int64) {
        // TODO
    }
    mutating func update(equityStatistics: Equity<LEI>.Statistics) {
        self.equity = equityStatistics
    }

    mutating func afterIndexCount(
        world _: borrowing GameWorld,
        context: ComputationPass
    ) throws {
        self.region = context.planets[self.state.tile]?.properties
    }
}
extension BuildingContext {
    private static var mothballing: Double { 0.1 }

    private static var attrition: Double { 0.01 }
    private static var restore: Double { 0.04 }
    private static var vertex: Double { 0.5 }

    private var restoration: Double? {
        guard self.state.z.fe > Self.vertex else {
            return nil
        }
        let parameter: Double = self.state.z.fe - Self.vertex
        return Self.restore * parameter
    }
    private var attrition: Double? {
        guard self.state.z.fe < Self.vertex else {
            return nil
        }
        let parameter: Double = Self.vertex - self.state.z.fe
        return Self.attrition * parameter
    }
}
extension BuildingContext: TransactingContext {
    mutating func allocate(turn: inout Turn) {
        guard
        let country: CountryProperties = self.region?.occupiedBy else {
            return
        }

        if  let mothball: Int64 = self.state.z.mothball(
                active: self.state.z.active,
                utilization: self.stats.utilization,
                utilizationThreshold: 1,
                rate: Self.mothballing,
                random: &turn.random
            ) {
            self.state.z.active -= mothball
            self.state.z.vacant += mothball
            self.state.mothballed = mothball
        } else {
            self.state.mothballed = 0
        }

        self.state.z.ei = 1

        self.state.inventory.out.sync(with: self.type.output, releasing: 1)
        self.state.inventory.l.sync(
            with: self.type.operations,
            scalingFactor: (self.state.z.active, self.state.z.ei),
        )
        self.state.inventory.e.sync(
            with: self.type.maintenance,
            scalingFactor: (self.state.z.total, self.state.z.ei),
        )
        self.state.inventory.x.sync(
            with: self.type.development,
            scalingFactor: (self.state.z.total, self.state.z.ei),
        )

        if  self.equity.sharePrice.n > 0 {
            self.state.z.px = Double.init(self.equity.sharePrice)
        } else {
            self.state.z.px = 0
            self.state.equity = [:]
            self.equity = .init()
        }

        let weights: (
            segmented: SegmentedWeights<InelasticDemand>,
            tradeable: AggregateWeights
        ) = (
            segmented: .business(
                l: self.state.inventory.l,
                e: self.state.inventory.e,
                x: self.state.inventory.x,
                markets: turn.localMarkets,
                address: self.state.tile,
            ),
            tradeable: .business(
                l: self.state.inventory.l,
                e: self.state.inventory.e,
                x: self.state.inventory.x,
                markets: turn.worldMarkets,
                currency: country.currency.id,
            )
        )

        let budget: Building.Budget = .init(
            account: turn.bank[account: self.lei],
            state: self.state.z,
            weights: weights,
            stockpileMaxDays: Self.stockpileDays.upperBound,
            d: (
                l: 30,
                e: 90,
                x: 365,
                v: self.stats.utilization * max(0, self.state.z.profitability)
            )
        )

        let sharesTarget: Int64 = self.state.z.total * self.type.sharesPerLevel + self.type.sharesInitial
        let sharesIssued: Int64 = max(0, sharesTarget - self.equity.shareCount)

        let sharesToIssue: Int64 = budget.buybacks == 0 ? sharesIssued : 0

        self.state.budget = budget

        // needs to be called even if quantity is zero, or the security will not
        // be tradeable today
        turn.stockMarkets.issueShares(
            currency: country.currency.id,
            quantity: sharesToIssue,
            security: self.security,
        )

        turn.localMarkets.tradeAsBusiness(
            selling: self.state.inventory.out.segmented,
            buying: weights.segmented,
            budget: (budget.l.segmented, budget.e.segmented, budget.x.segmented),
            as: self.lei,
            in: self.state.tile
        )
    }

    mutating func transact(turn: inout Turn) {
        guard
        let country: CountryProperties = self.region?.occupiedBy,
        let budget: Building.Budget = self.state.budget else {
            return
        }

        {
            let stockpileTarget: ResourceStockpileTarget = .random(
                in: Self.stockpileDays,
                using: &turn.random,
            )

            if  budget.l.tradeable > 0 {
                $0 += self.state.inventory.l.tradeAsBusiness(
                    stockpileDays: stockpileTarget,
                    spendingLimit: budget.l.tradeable,
                    in: country.currency.id,
                    on: &turn.worldMarkets,
                )
            }
            if  budget.e.tradeable > 0 {
                $0 += self.state.inventory.e.tradeAsBusiness(
                    stockpileDays: stockpileTarget,
                    spendingLimit: budget.e.tradeable,
                    in: country.currency.id,
                    on: &turn.worldMarkets,
                )
            }
            if  budget.x.tradeable > 0 {
                $0 += self.state.inventory.x.tradeAsBusiness(
                    stockpileDays: stockpileTarget,
                    spendingLimit: budget.x.tradeable,
                    in: country.currency.id,
                    on: &turn.worldMarkets,
                )
            }

            #assert(
                $0.balance >= 0,
                """
                Building (id = \(self.id), type = '\(self.type.symbol)') has negative cash! \
                (\($0))
                """
            )

            $0.r += self.state.inventory.out.sell(
                in: country.currency.id,
                on: &turn.worldMarkets
            )
        } (&turn.bank[account: self.lei])

        self.state.inventory.out.deposit(
            from: self.type.output,
            scalingFactor: (self.state.z.active, 1)
        )
        self.state.inventory.l.consume(
            from: self.type.operations,
            scalingFactor: (self.state.z.active, self.state.z.ei)
        )
        self.state.inventory.e.consume(
            from: self.type.maintenance,
            scalingFactor: (self.state.z.total, self.state.z.ei)
        )
        if  self.state.inventory.x.full {
            // in this situation, `active` is usually close to or equal to `total`
            self.state.created = max(1, self.state.z.total / 256)
            self.state.z.active += self.state.created
            self.state.inventory.x.consume(
                from: self.type.development,
                scalingFactor: (self.state.z.total, self.state.z.ei)
            )
        } else {
            self.state.created = 0
        }

        self.state.z.fl = self.state.inventory.l.fulfilled
        self.state.z.fe = self.state.inventory.e.fulfilled
        self.state.z.fx = self.state.inventory.x.fulfilled

        self.state.spending.buybacks += turn.bank.buyback(
            security: self.security,
            budget: budget.buybacks,
            equity: &self.state.equity,
            random: &turn.random,
        )
        self.state.spending.dividend += turn.bank.transfer(
            budget: budget.dividend,
            source: self.lei,
            recipients: self.state.equity.shares.values.shuffled(
                using: &turn.random.generator
            )
        )

        let profit: ProfitMargins = self.state.profit
        self.state.z.mix(profitability: profit.marginalProfitability)
    }

    mutating func advance(turn: inout Turn) {
        self.state.destroyed = 0
        self.state.restored = 0

        if  let attrition: Double = self.attrition {
            if  self.state.z.vacant > 0 {
                let destroyed: Int64 = Binomial[self.state.z.vacant, attrition].sample(
                    using: &turn.random.generator
                )
                self.state.z.vacant -= destroyed
                self.state.destroyed += destroyed
            }
        } else if self.state.mothballed == 0,
            let restoration: Double = self.restoration {
            // if doesn’t make sense to restore buildings if mothballing is occurring
            if  self.state.z.vacant > 0 {
                let restored: Int64 = Binomial[self.state.z.vacant, restoration].sample(
                    using: &turn.random.generator
                )
                self.state.z.active += restored
                self.state.z.vacant -= restored
                self.state.restored += restored
            }
        }

        self.state.z.vl = self.state.inventory.l.valueAcquired
        self.state.z.ve = self.state.inventory.e.valueAcquired
        self.state.z.vx = self.state.inventory.x.valueAcquired

        guard
        let country: CountryProperties = self.region?.occupiedBy else {
            return
        }

        self.state.equity.split(
            price: self.state.z.px,
            turn: &turn,
            notifying: [country.id]
        )
    }
}
extension BuildingContext {
    func explainProduction(_ ul: inout TooltipInstructionEncoder, base: Int64) {
        ul["Production per facility"] = base[/3]
    }
    func explainNeeds(
        _ ul: inout TooltipInstructionEncoder, base: Int64) {
        let efficiency: Double = self.state.z.ei
        ul["Demand per facility"] = (efficiency * Double.init(base))[..3]
        ul[>] {
            $0["Base"] = base[/3]
            $0["Efficiency", -] = +?(efficiency - 1)[%2]
        }
    }
}
extension BuildingContext: LegalEntityTooltipBearing {
    func tooltipExplainPrice(
        _ line: InventoryLine,
        market: (segmented: LocalMarketSnapshot?, tradeable: BlocMarket.State?)
    ) -> Tooltip? {
        switch line {
        case .l(let id):
            return self.state.inventory.l.tooltipExplainPrice(id, market)
        case .e(let id):
            return self.state.inventory.e.tooltipExplainPrice(id, market)
        case .x(let id):
            return self.state.inventory.x.tooltipExplainPrice(id, market)
        case .o(let id):
            return self.state.inventory.out.tooltipExplainPrice(id, market)
        case .m:
            return nil
        }
    }
}
extension BuildingContext {
    func tooltipAccount(_ account: Bank.Account) -> Tooltip? {
        let profit: ProfitMargins = self.state.profit
        let liquid: TurnDelta<Int64> = account.Δ
        let assets: TurnDelta<Int64> = self.state.Δ.vl + self.state.Δ.ve + self.state.Δ.vx

        return .instructions {
            $0["Total valuation", +] = (liquid + assets)[/3]
            $0[>] {
                $0["Today’s profit", +] = +profit.operating[/3]
                $0["Gross margin", +] = profit.grossMargin.map {
                    (Double.init($0))[%2]
                }
                $0["Operating margin", +] = profit.operatingMargin.map {
                    (Double.init($0))[%2]
                }
            }

            $0["Illiquid assets", +] = assets[/3]
            $0["Liquid assets", +] = liquid[/3]
            $0[>] {
                let excluded: Int64 = self.state.spending.totalExcludingEquityPurchases
                $0["Market spending", +] = +(account.b + excluded)[/3]
                $0["Market earnings", +] = +?account.r[/3]
                $0["Subsidies", +] = +?account.s[/3]
                $0["Interest and dividends", +] = +?(-self.state.spending.dividend)[/3]
                $0["Stock buybacks", +] = (-self.state.spending.buybacks)[/3]
                if account.e > 0 {
                    $0["Market capitalization", +] = +account.e[/3]
                }
            }
        }
    }
    func tooltipActive() -> Tooltip? {
        .instructions {
            $0["Active facilities", +] = self.state.Δ.active[/3]
            $0[>] {
                $0["Backgrounding", +] = +?(-self.state.mothballed)[/3]
                $0["Restoration", +] = +?self.state.restored[/3]
                $0["Development", +] = +?self.state.created[/3]
            }
            let total: Int64 = self.state.z.total
            $0[>] = """
            There \(total == 1 ? "is" : "are") \(em: total[/3]) total \
            \(total == 1 ? "facility" : "facilities") in this region
            """
        }
    }
    func tooltipVacant() -> Tooltip? {
        .instructions {
            $0["Vacant facilities", -] = self.state.Δ.vacant[/3]
            $0[>] {
                $0["Backgrounding", -] = +?self.state.mothballed[/3]
                $0["Restoration", -] = +?(-self.state.restored)[/3]
                $0["Attrition", +] = +?(-self.state.destroyed)[/3]
            }
        }
    }
    func tooltipNeeds(_ tier: ResourceTierIdentifier) -> Tooltip? {
        .instructions {
            switch tier {
            case .l:
                let inputs: ResourceInputs = self.state.inventory.l
                $0["Operational needs fulfilled"] = self.state.z.fl[%2]
                $0[>] {
                    $0["Market spending (amortized)", +] = inputs.valueConsumed[/3]
                }
                $0[>] = """
                Only \(em: "active") facilities consume operational resources
                """
            case .e:
                let inputs: ResourceInputs = self.state.inventory.e
                $0["Maintenance needs fulfilled"] = self.state.z.fe[%2]
                $0[>] {
                    $0["Restoration", +] = self.restoration.map { +$0[%2] }
                    $0["Attrition", +] = self.attrition.map { +(-$0)[%2] }
                    $0["Market spending (amortized)", +] = inputs.valueConsumed[/3]
                }
                $0[>] = """
                All facilities consume maintenance resources, even when \(em: "backgrounded")
                """
            case .x:
                $0["Development needs fulfilled"] = self.state.z.fx[%2]
            }
        }
    }
}
