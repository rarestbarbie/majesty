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

    // TODO; these should probably not be here
    let _factories: OrderedDictionary<FactoryID, FactoryJob>
    let _mines: OrderedDictionary<MineID, MiningJob>
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
            _factories: state.factories,
            _mines: state.mines
        )
    }
}
extension PopSnapshot: PopFactors {
    typealias Matrix = ConditionBreakdown
}
extension PopSnapshot: LegalEntitySnapshot {}
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
        mine: MiningJobConditions
    ) {
        ul["Production per miner"] = (mine.factor * Double.init(base))[..3]
        ul[>] {
            $0["Base"] = base[/3]
        }

        ul["Mining efficiency"] = mine.factor[%1]
        ul[>] {
            switch self.type.occupation {
            case .Politician: self.explainProductionPolitician(&$0, base: base, mine: mine)
            case .Miner: self.explainProductionMiner(&$0, base: base, mine: mine)
            default: break
            }
        }
    }
    private func explainProductionPolitician(
        _ ul: inout TooltipInstructionEncoder,
        base: Int64,
        mine: MiningJobConditions
    ) {
        ul[>] = "Base: \(em: MineMetadata.efficiencyPoliticians[%])"
        ul["Militancy of Free Population", +] = +(
            MineMetadata.efficiencyPoliticiansPerMilitancyPoint * self.region.pops.free.μ.mil
        )[%1]
    }
    private func explainProductionMiner(
        _ ul: inout TooltipInstructionEncoder,
        base: Int64,
        mine: MiningJobConditions
    ) {
        guard
        let modifiers: CountryModifiers.Stack<
            Decimal
        > = self.region.modifiers.miningEfficiency[mine.type] else {
            return
        }

        ul[>] = "Base: \(em: MineMetadata.efficiencyMiners[%])"
        for (effect, provenance): (Decimal, EffectProvenance) in modifiers.blame {
            ul[provenance.name, +] = +effect[%]
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
    func tooltipAccount(_ account: Bank.Account) -> Tooltip? {
        let liquid: Delta<Int64> = account.Δ
        let assets: Delta<Int64> = self.Δ.assets
        let valuation: Delta<Int64> = liquid + assets

        return .instructions {
            if case .Ward = self.type.stratum {
                let profit: FinancialStatement.Profit = self.stats.financial.profit
                $0["Total valuation", +] = valuation[/3]
                $0[>] {
                    $0["Today’s profit", +] = +profit.operating[/3]
                    $0["Gross margin", +] = profit.grossMargin.map {
                        (Double.init($0))[%2]
                    }
                    $0["Operating margin", +] = profit.operatingMargin.map {
                        (Double.init($0))[%2]
                    }
                }
            }

            $0["Illiquid assets", +] = assets[/3]
            $0["Liquid assets", +] = liquid[/3]
            $0[>] {
                let excluded: Int64 = self.spending.totalExcludingEquityPurchases
                $0["Welfare", +] = +?account.s[/3]
                $0[self.occupation.earnings, +] = +?account.r[/3]
                $0["Interest and dividends", +] = +?account.i[/3]

                $0["Market spending", +] = +?(account.b - excluded)[/3]
                $0["Stock sales", +] = +?account.j[/3]
                if case .Ward = self.type.stratum {
                    $0["Loans taken", +] = +?account.e[/3]
                } else {
                    $0["Investments", +] = +?account.e[/3]
                }

                $0["Inheritances", +] = +?account.d[/3]
            }
        }
    }
    func tooltipActive() -> Tooltip? {
        .instructions {
            $0["Active slaves", +] = self.Δ.active[/3]
            $0[>] {
                $0["Backgrounding", +] = +?(-self.mothballed)[/3]
                $0["Rehabilitation", +] = +?self.restored[/3]
                $0["Breeding", +] = +?self.created[/3]
            }
        }
    }
    func tooltipActiveHelp() -> Tooltip? {
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
    func tooltipVacant() -> Tooltip? {
        .instructions {
            $0["Backgrounded slaves", -] = self.Δ.vacant[/3]
            $0[>] {
                $0["Backgrounding", -] = +?self.mothballed[/3]
                $0["Rehabilitation", -] = +?(-self.restored)[/3]
                $0["Attrition", +] = +?(-self.destroyed)[/3]
            }
        }
    }
    func tooltipVacantHelp() -> Tooltip? {
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
    func tooltipNeeds(_ tier: ResourceTierIdentifier) -> Tooltip? {
        return .instructions {
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
    func tooltipOccupation() -> Tooltip? {
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
            let miningConditions: MiningJobConditions = self.mines[id.mine] else {
                return nil
            }
            return self.inventory[.m(id)]?.tooltipSupply(tier: miningConditions.output) {
                self.explainProduction(&$0, base: $1, mine: miningConditions)
            }
        }
    }
}
extension PopSnapshot {
    func tooltipJobs(
        factories: [FactoryID: FactorySnapshot],
        mines: [MineID: MineSnapshot],
        rules: GameMetadata,
    ) -> Tooltip? {
        switch self.occupation.mode {
        case .mining:
            return self.tooltipPopJobs(list: self._mines.values.elements) {
                mines[$0]?.metadata.title ?? "Unknown"
            }

        case .remote, .hourly:
            return self.tooltipPopJobs(list: self._factories.values.elements) {
                factories[$0]?.metadata.title ?? "Unknown"
            }

        case .aristocratic, .livestock:
            return .instructions {
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
    private func tooltipPopJobs<Job>(
        list: [Job],
        name: (Job.ID) -> String
    ) -> Tooltip where Job: PopJob {
        let total: (
            count: Int64,
            hired: Int64,
            fired: Int64,
            quit: Int64
        ) = list.reduce(into: (0, 0, 0, 0)) {
            $0.count += $1.count
            $0.hired += $1.hired
            $0.fired += $1.fired
            $0.quit += $1.quit
        }

        return .instructions {
            $0["Total employment"] = total.count[/3]
            $0[>] {
                for job: Job in list {
                    let change: Int64 = job.hired - job.fired - job.quit
                    $0[name(job.id), +] = job.count[/3] <- job.count - change
                }
            }
            $0["Today’s change", +] = +?(total.hired - total.fired - total.quit)[/3]
            $0[>] {
                $0["Hired today", +] = +?total.hired[/3]
                $0["Fired today", +] = ??(-total.fired)[/3]
                $0["Quit today", +] = ??(-total.quit)[/3]
            }
        }
    }
}