import D
import Fraction
import GameConditions
import GameEconomy
import GameIDs
import GameRules
import GameState
import GameUI
import OrderedCollections

struct PopSnapshot: PopProperties, Sendable {
    let metadata: PopMetadata
    let stats: Pop.Stats
    let region: RegionalProperties
    let mines: [MineID: MiningJobConditions]

    let id: PopID
    let type: PopType
    let tile: Address

    let mothballed: Int64
    let destroyed: Int64
    let restored: Int64
    let created: Int64

    let inventory: InventorySnapshot
    let spending: Pop.Spending
    let budget: Pop.Budget?
    let y: Pop.Dimensions
    let z: Pop.Dimensions

    let equity: Equity<LEI>.Snapshot
    let jobs: Jobs?
}
extension PopSnapshot {
    init(
        metadata: PopMetadata,
        stats: Pop.Stats,
        region: RegionalProperties,
        equity: Equity<LEI>.Statistics,
        mines: [MineID: MiningJobConditions],
        state: Pop,
    ) {
        let jobs: Jobs? = state.occupation.employer.map {
            switch $0 {
            case .factory: .factories(state.factories.values.elements)
            case .mine: .mines(state.mines.values.elements)
            }
        }

        self.init(
            metadata: metadata,
            stats: stats,
            region: region,
            mines: mines,
            id: state.id,
            type: state.type,
            tile: state.tile,
            mothballed: state.mothballed,
            destroyed: state.destroyed,
            restored: state.restored,
            created: state.created,
            inventory: .pop(state),
            spending: state.spending,
            budget: state.budget,
            y: state.y,
            z: state.z,
            equity: .init(equity: state.equity, stats: equity),
            jobs: jobs,
        )
    }
}
extension PopSnapshot: PopFactors {
    typealias Matrix = ConditionBreakdown
}
extension PopSnapshot: LegalEntitySnapshot, BusinessSnapshot {}
extension PopSnapshot {
    private func estimateIncomeFromEmployment(
        factories: [FactoryID: FactorySnapshot],
        mines: [MineID: MineSnapshot],
    ) -> (min: Double, median: Double, max: Double)? {
        var yields: [(count: Int64, value: Double)]
        switch self.jobs {
        case nil:
            return nil
        case .mines(let jobs)?:
            if case .Elite = self.occupation.stratum {
                return nil
            } else {
                yields = jobs.map { ($0.count, mines[$0.id]?.z.yieldPerMiner ?? 0) }
            }
        case .factories(let jobs)?:
            if case .Worker = self.occupation.stratum {
                yields = jobs.map { ($0.count, Double.init(factories[$0.id]?.z.wn ?? 0)) }
            } else {
                yields = jobs.map { ($0.count, Double.init(factories[$0.id]?.z.cn ?? 0)) }
            }
        }

        // for expected lengths of jobs list, sorting is probably faster than specialized
        // median-finding algorithms
        yields.sort { $0.value < $1.value }

        guard
        let min: Double = yields.first?.value,
        let max: Double = yields.last?.value,
        let median: Double = yields.medianAssumingAscendingOrder() else {
            return nil
        }

        return (min: min, median: median, max: max)
    }
}
extension PopSnapshot {
    private func explainProduction(_ ul: inout TooltipInstructionEncoder, base: Int64) {
        ul["Production per worker"] = Double.init(base)[..3]
        ul[>] {
            $0["Base"] = base[/3]
            $0["Productivity", +] = (1 as Double)[%2]
        }
    }
    private func explainProduction(
        _ ul: inout TooltipInstructionEncoder,
        base: Int64,
        mine: MineSnapshot,
        mineConditions: MiningJobConditions
    ) {
        ul["Production per miner"] = (
            mineConditions.efficiencyPerMiner * Double.init(base)
        )[/3..3]

        ul[>] {
            $0["Base"] = base[/3]
            $0["Parceling", +] = +?(mine.z.parcelFraction - 1)[%]
        }

        ul["Mining efficiency", +] = mine.Δ.efficiency[%1]
        ul[>] {
            switch self.type.occupation {
            case .Politician:
                let mil: Double = self.region.stats.voters.μ.mil
                let rate: Double = MineMetadata.efficiencyPoliticiansPerMilitancyPoint
                $0["Base"] = MineMetadata.efficiencyPoliticians[%]
                $0["Militancy of Free Population", +] = +(rate * mil)[%1]

            case .Miner:
                guard
                let modifiers: CountryModifiers.Stack<
                    Decimal
                > = self.region.modifiers.miningEfficiency[mine.type] else {
                    return
                }

                $0["Base"] = MineMetadata.efficiencyMiners[%]

                for (effect, provenance): (Decimal, EffectProvenance) in modifiers.blame {
                    $0[provenance.name, +] = +effect[%]
                }
            default: break
            }
        }
    }

    private func explainNeeds(_ ul: inout TooltipInstructionEncoder, l: Int64) {
        self.explainNeeds(&ul, base: l, needsScalePerCapita: self.needsScalePerCapita.l)
    }
    private func explainNeeds(_ ul: inout TooltipInstructionEncoder, e: Int64) {
        self.explainNeeds(&ul, base: e, needsScalePerCapita: self.needsScalePerCapita.e)
    }
    private func explainNeeds(_ ul: inout TooltipInstructionEncoder, x: Int64) {
        self.explainNeeds(&ul, base: x, needsScalePerCapita: self.needsScalePerCapita.x)
    }
    private func explainNeeds(
        _ ul: inout TooltipInstructionEncoder,
        base: Int64,
        needsScalePerCapita: Double
    ) {
        ul["Demand per capita"] = (needsScalePerCapita * Double.init(base))[..3]
        ul[>] {
            $0["Base"] = base[/3]
            $0["Consciousness", -] = +?(needsScalePerCapita - 1)[%2]
        }
    }
}
extension PopSnapshot {
    func tooltipAccount(_ account: Bank.Account) -> Tooltip {
        return .instructions {
            if case .Ward = self.type.stratum {
                self.explain(statement: self.stats.financial, account: account, tooltip: &$0)
                return
            }

            let weight: Double = Double.init(self.z.total)
            let income: Mean<Int64> = .init(
                fields: self.stats.financial.incomeSelfEmployment + account.i + account.s,
                weight: weight
            )

            $0["Per-capita income", +] = +(income.defined ?? 0)[/3..2]
            $0[>] {
                let account: Mean<Bank.Account> = .init(
                    fields: account,
                    weight: weight
                )
                let statement: Mean<FinancialStatement> = .init(
                    fields: self.stats.financial,
                    weight: weight
                )
                if case .Elite = self.occupation.stratum {
                    $0["Fundraising", +] = +?statement.incomeSelfEmployment[/3..2]
                    $0["Interest and dividends", +] = +?account.i[/3..2]
                } else {
                    $0["Self-employment", +] = +?statement.incomeSelfEmployment[/3..2]
                    $0["From employment", +] = +?account.i[/3..2]
                }

                $0["Welfare", +] = +?account.s[/3..2]
            }

            $0["Liquid net worth", +] = account.Δ[/3]
            $0[>] {
                $0[self.occupation.s, +] = +?account.s[/3]
                $0[self.occupation.i, +] = +?account.i[/3]
                $0["Investments", +] = +?account.e[/3]
                $0["Stock sales", +] = +?account.f[/3]
                $0["Market spending", +] = +account.b[/3]
                $0[self.occupation.c, +] = +?account.c[/3]
                $0["Inheritances", +] = +?account.d[/3]
            }
        }
    }
    func tooltipActive() -> Tooltip {
        .instructions {
            $0["Active slaves", +] = self.Δ.active[/3]
            $0[>] {
                $0["Backgrounding", +] = +?(-self.mothballed)[/3]
                $0["Rehabilitation", +] = +?self.restored[/3]
                $0["Breeding", +] = +?self.created[/3]
            }
        }
    }
    func tooltipActiveHelp() -> Tooltip {
        .instructions {
            let slaveBreedingEfficiency: Decimal = PopContext.slaveBreedingBase
                + self.region.modifiers.livestockBreedingEfficiency.value
            let slaveBreedingRate: Double = Double.init(
                slaveBreedingEfficiency
            ) * self.developmentRate(utilization: 1)

            $0["Breeding rate", +] = slaveBreedingRate[%2]
            $0[>] {
                $0["Profitability", +] = max(0, self.z.profitability)[%1]
                $0["Background population", +] = +?(
                    self.developmentRateVacancyFactor - 1
                )[%2]
            }
            $0["Breeding efficiency", +] = slaveBreedingEfficiency[%]
            $0[>] {
                $0["Base"] = PopContext.slaveBreedingBase[%]
                for (effect, provenance): (Decimal, EffectProvenance)
                    in self.region.modifiers.livestockBreedingEfficiency.blame {
                    $0[provenance.name, +] = +effect[%]
                }
            }

            let total: Int64 = self.z.total
            $0[>] = """
            There \(total == 1 ? "is" : "are") \(em: total[/3]) total \
            \(total == 1 ? "slave" : "slaves") of this type in this region
            """
        }
    }
    func tooltipVacant() -> Tooltip {
        .instructions {
            $0["Backgrounded slaves", -] = self.Δ.vacant[/3]
            $0[>] {
                $0["Backgrounding", -] = +?self.mothballed[/3]
                $0["Rehabilitation", -] = +?(-self.restored)[/3]
                $0["Attrition", +] = +?(-self.destroyed)[/3]
            }
        }
    }
    func tooltipVacantHelp() -> Tooltip {
        .instructions {
            let attrition: Double = self.attrition ?? 0

            let slaveCullingEfficiency: Decimal = PopContext.slaveCullingBase
                + self.region.modifiers.livestockCullingEfficiency.value
            let slaveCullingRate: Double = Double.init(
                slaveCullingEfficiency
            ) * attrition

            $0["Culling rate"] = slaveCullingRate[%2]
            $0[>] {
                $0["Everyday needs fulfilled", -] = +(attrition - 1)[%1]
            }

            $0["Culling efficiency", +] = slaveCullingEfficiency[%]
            $0[>] {
                $0[>] = "Base: \(em: PopContext.slaveCullingBase[%])"
                for (effect, provenance): (Decimal, EffectProvenance)
                    in self.region.modifiers.livestockCullingEfficiency.blame {
                    $0[provenance.name, +] = +effect[%]
                }
            }

            $0[>] = """
            Unsold slaves may be \(em: "backgrounded") for a time to reduce upkeep and allow \
            the market to rebalance
            """
        }
    }
    func tooltipNeeds(_ tier: ResourceTierIdentifier) -> Tooltip {
        .instructions {
            let valueConsumed: Int64 = self.inventory.valueConsumed(tier: tier)
            switch tier {
            case .l:
                $0["Life needs fulfilled"] = self.z.fl[%2]
                $0[>] {
                    $0["Market spending (amortized)", +] = valueConsumed[/3]
                    $0["Militancy", -] = +?PopContext.mil(fl: self.z.fl)[..3]
                    $0["Consciousness", -] = +?PopContext.con(fl: self.z.fl)[..3]
                }
            case .e:
                $0["Everyday needs fulfilled"] = self.z.fe[%2]
                $0[>] {
                    $0["Market spending (amortized)", +] = valueConsumed[/3]
                    $0["Militancy", -] = +?PopContext.mil(fe: self.z.fe)[..3]
                    $0["Consciousness", -] = +?PopContext.con(fe: self.z.fe)[..3]
                }
            case .x:
                $0["Luxury needs fulfilled"] = self.z.fx[%2]
                $0[>] {
                    $0["Market spending (amortized)", +] = valueConsumed[/3]
                    if let budget: Pop.Budget = self.budget, budget.investment > 0 {
                            $0["Investment budget", +] = budget.investment[/3]
                    }

                    $0["Militancy", -] = +?PopContext.mil(fx: self.z.fx)[..3]
                    $0["Consciousness", -] = +?PopContext.con(fx: self.z.fx)[..3]
                }
            }
        }
    }
    func tooltipOccupation() -> Tooltip {
        let promotion: ConditionBreakdown = self.promotion
        let demotion: ConditionBreakdown = self.demotion

        let promotions: Int64 = promotion.output > 0
            ? .init(Double.init(self.z.active) * promotion.output * 30)
            : 0
        let demotions: Int64 = demotion.output > 0
            ? .init(Double.init(self.z.active) * demotion.output * 30)
            : 0

        return .conditions(
            .list(
                "We expect \(em: promotions) promotion(s) in the next month",
                breakdown: promotion
            ),
            .list(
                "We expect \(em: demotions) demotion(s) in the next month",
                breakdown: demotion
            ),
        )
    }
    func tooltipResourceIO(
        _ line: InventoryLine,
        mines: [MineID: MineSnapshot]
    ) -> Tooltip? {
        switch line {
        case .l(let resource):
            return self.inventory[.l(resource)]?.tooltipDemand(
                tier: self.metadata.l,
                details: self.explainNeeds(_:l:)
            )
        case .e(let resource):
            return self.inventory[.e(resource)]?.tooltipDemand(
                tier: self.metadata.e,
                details: self.explainNeeds(_:e:)
            )
        case .x(let resource):
            return self.inventory[.x(resource)]?.tooltipDemand(
                tier: self.metadata.x,
                details: self.explainNeeds(_:x:)
            )
        case .o(let resource):
            return self.inventory[.o(resource)]?.tooltipSupply(
                tier: self.metadata.output,
                details: self.explainProduction(_:base:)
            )
        case .m(let id):
            guard
            let mine: MineSnapshot = mines[id.mine],
            let mineConditions: MiningJobConditions = self.mines[id.mine] else {
                return nil
            }
            return self.inventory[.m(id)]?.tooltipSupply(tier: mineConditions.output) {
                self.explainProduction(&$0, base: $1, mine: mine, mineConditions: mineConditions)
            }
        }
    }
}
extension PopSnapshot {
    func tooltipJobHelp(
        factories: [FactoryID: FactorySnapshot],
        mines: [MineID: MineSnapshot],
        rules: GameMetadata,
    ) -> Tooltip {
        .instructions {
            let income: Double
            if  let jobType: PopJobType = self.occupation.employer {
                let w: (
                    min: Double,
                    median: Double,
                    max: Double
                )? = self.estimateIncomeFromEmployment(factories: factories, mines: mines)

                if  case .Elite = self.occupation.stratum {
                    let r²: Double = PopJobType.r0
                    $0["Median quit rate"] = (jobType.q0 * r²)[%2]

                    income = self.region.stats.incomeElite[self.type.gender.sex].μ.incomeTotal
                } else {
                    let w0: Double = self.region.stats.w0(self.type)
                    let r²: Double = PopJobType.r²(yield: w?.median ?? w0, referenceWage: w0)
                    $0["Median quit rate"] = (jobType.q0 * r²)[%2]
                    $0[>] {
                        $0["Base"] = (jobType.q0 * PopJobType.r0)[%2]
                        $0["Relative earnings", -] = +?(r² / PopJobType.r0 - 1)[%2]
                    }

                    income = w0
                }

                if  let (min, median, max): (Double, Double, Double) = w {
                    let label: String
                    switch jobType {
                    case .mine:
                        label = "mining yield"
                    case .factory:
                        label = self.occupation.stratum > .Worker ? "salary" : "wage"
                    }
                    $0["Median \(label)"] = median[/3..2]
                    $0[>] {
                        $0["Lowest"] = min[/3..2]
                        $0["Highest"] = max[/3..2]
                    }
                }
            } else {
                if  case .Elite = self.occupation.stratum {
                    income = self.region.stats.incomeElite[type.gender.sex].μ.incomeTotal
                } else {
                    income = self.region.stats.w0(self.type)
                }
            }

            if  case .Elite = self.occupation.stratum {
                $0[>] = """
                The average rent extracted by \(em: self.type.gender.sex.pluralLowercased) \
                in this income stratum and region is \(em: income[/3..2]) per day
                """
            } else {
                $0[>] = """
                The average income earned by \(em: self.type.gender.sex.pluralLowercased) \
                in this income stratum and region is \(em: income[/3..2]) per day
                """
            }
            if  case _? = self.occupation.employer, self.occupation.stratum < .Elite {
                $0[>] = """
                Pops are much less likely to quit jobs that pay well compared to the \
                average income of their peers
                """
            }
        }
    }

    func tooltipJobList(
        factories: [FactoryID: FactorySnapshot],
        mines: [MineID: MineSnapshot],
        rules: GameMetadata,
    ) -> Tooltip {
        switch self.jobs {
        case .factories(let jobs)?:
            return Self.tooltipPopJobList(list: jobs) {
                factories[$0]?.metadata.title ?? "Unknown"
            }

        case .mines(let jobs)?:
            return Self.tooltipPopJobList(list: jobs) {
                mines[$0]?.metadata.title ?? "Unknown"
            }

        case nil:
            return self.tooltipPopSelfEmployment(rules: rules)
        }
    }
    func tooltipJobs(rules: GameMetadata) -> Tooltip {
        switch self.jobs {
        case .factories(let jobs)?:
            return Self.tooltipPopJobs(list: jobs)
        case .mines(let jobs)?:
            return Self.tooltipPopJobs(list: jobs)
        case nil:
            return self.tooltipPopSelfEmployment(rules: rules)
        }
    }

    // this is shared across two UI elements
    private func tooltipPopSelfEmployment(rules: GameMetadata) -> Tooltip {
        .instructions {
            $0["Total employment"] = self.stats.employedBeforeEgress[/3]
            for produced: InventorySnapshot.Produced in self.inventory.production() {
                let output: ResourceOutput = produced.output
                let name: String = rules.resources[output.id].title
                $0[>] = """
                Today these \(self.occupation.plural) sold \(
                    output.unitsSold[/3],
                    style: output.unitsSold < output.units.added ? .neg : .pos
                ) of \
                \(em: output.units.added[/3]) \(name) produced
                """
            }
        }
    }
}
extension PopSnapshot {
    private static func tooltipPopJobList<Job>(
        list: [Job],
        name: (Job.ID) -> String
    ) -> Tooltip where Job: PopJob {
        .instructions {
            let total: (
                count: Int64,
                hired: Int64,
                fired: Int64,
                quit: Int64
            ) = Self.aggregatePopJobs(list: list)
            $0["Total employment", +] = total.count[/3] ^^ (
                total.hired - total.fired - total.quit
            )
            $0[>] {
                for job: Job in list {
                    $0[name(job.id), +] = job.count[/3] ^^ (job.hired - job.fired - job.quit)
                }
            }
        }
    }
    private static func tooltipPopJobs(list: [some PopJob]) -> Tooltip {
        .instructions {
            let total: (
                count: Int64,
                hired: Int64,
                fired: Int64,
                quit: Int64
            ) = Self.aggregatePopJobs(list: list)
            $0["Total employment", +] = total.count[/3] ^^ (
                total.hired - total.fired - total.quit
            )
            $0[>] {
                $0["Hired today", +] = +?total.hired[/3]
                $0["Fired today", +] = ??(-total.fired)[/3]
                $0["Quit today", +] = ??(-total.quit)[/3]
            }
        }
    }

    private static func aggregatePopJobs(list: [some PopJob]) -> (
        count: Int64,
        hired: Int64,
        fired: Int64,
        quit: Int64
    ) {
        list.reduce(into: (0, 0, 0, 0)) {
            $0.count += $1.count
            $0.hired += $1.hired
            $0.fired += $1.fired
            $0.quit += $1.quit
        }
    }
}
