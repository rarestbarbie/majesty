import D
import Fraction
import GameConditions
import GameEconomy
import GameIDs
import GameRules
import GameState
import GameUI

extension PopSnapshot {
    func buildDemotionMatrix<Matrix>(
        type: Matrix.Type = Matrix.self,
    ) -> Matrix where Matrix: ConditionMatrix<Decimal, Double> {
        .init(base: 0%) {
            if self.state.type.occupation.aristocratic {
                $0[true] {
                    $0 = -2‰
                } = { "\(+$0[%]): Pop is \(em: "aristocratic")" }
            } else {
                $0[1 - self.stats.employmentBeforeEgress] {
                    $0[$1 >= 0.1] = +2‱
                    $0[$1 >= 0.2] = +1‱
                    $0[$1 >= 0.3] = +1‱
                    $0[$1 >= 0.4] = +1‱
                } = { "\(+$0[%]): Unemployment is above \(em: $1[%0])" }
            }

            $0[self.state.y.fl] {
                $0[$1 < 1.00] = +1‰
                $0[$1 < 0.75] = +5‰
                $0[$1 < 0.50] = +2‰
                $0[$1 < 0.25] = +2‰
            } = { "\(+$0[%]): Getting less than \(em: $1[%0]) of Life Needs" }

        } factors: {
            $0[self.state.y.fx] {
                $0[$1 > 0.25] = -90%
            } = { "\(+$0[%]): Getting more than \(em: $1[%0]) of Luxury Needs" }
            $0[self.state.y.fe] {
                $0[$1 > 0.75] = -50%
                $0[$1 > 0.5] = -25%
            } = { "\(+$0[%]): Getting more than \(em: $1[%0]) of Everyday Needs" }

            $0[self.state.y.mil] {
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

            let culture: Culture = self.region.culturePreferred
            if case .Ward = self.state.type.stratum {
                $0[true] {
                    $0 = -100%
                } = { "\(+$0[%]): Pop is \(em: "enslaved")" }
            } else if self.state.race == culture.id {
                $0[true] {
                    $0 = -5%
                } = { "\(+$0[%]): Culture is \(em: culture.name)" }
            } else {
                $0[true] {
                    $0 = +100%
                } = { "\(+$0[%]): Culture is not \(em: culture.name)" }
            }
        }
    }

    func buildPromotionMatrix<Matrix>(
        type: Matrix.Type = Matrix.self,
    ) -> Matrix where Matrix: ConditionMatrix<Decimal, Double> {
        .init(base: 0%) {
            $0[self.state.y.mil] {
                $0[$1 >= 3.0] = -2‱
                $0[$1 >= 5.0] = -2‱
                $0[$1 >= 7.0] = -3‱
                $0[$1 >= 9.0] = -3‱
            } = { "\(+$0[%]): Militancy is above \(em: $1[..1])" }

            switch self.state.type.stratum {
            case .Owner:
                $0[self.state.y.fx] {
                    $0[$1 >= 0.25] = +3‰
                    $0[$1 >= 0.50] = +3‰
                    $0[$1 >= 0.75] = +3‰
                } = { "\(+$0[%]): Getting more than \(em: $1[%0]) of Luxury Needs" }

            case _:
                break
            }

            $0[self.state.y.con] {
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
            $0[self.state.y.fl] {
                $0[$1 < 1.00] = -100%
            } = { "\(+$0[%]): Getting less than \(em: $1[%0]) of Life Needs" }

            $0[self.state.y.fe] {
                $0[$1 >= 0.1] = -10%
                $0[$1 >= 0.2] = -10%
                $0[$1 >= 0.3] = -10%
                $0[$1 >= 0.4] = -10%
                $0[$1 >= 0.5] = -10%
                $0[$1 >= 0.6] = -10%
                $0[$1 >= 0.7] = -10%
                $0[$1 >= 0.8] = -10%
                $0[$1 >= 0.9] = -10%
            } = { "\(+$0[%]): Getting more than \(em: $1[%0]) of Everyday Needs" }

            $0[self.state.y.mil] {
                $0[$1 >= 2.0] = -20%
                $0[$1 >= 4.0] = -10%
                $0[$1 >= 6.0] = -10%
                $0[$1 >= 8.0] = -10%
            } = { "\(+$0[%]): Militancy is above \(em: $1[..1])" }

            let culture: Culture = self.region.culturePreferred
            if case .Ward = self.state.type.stratum {
                $0[true] {
                    $0 = -100%
                } = { "\(+$0[%]): Pop is \(em: "enslaved")" }
            } else if self.state.race == culture.id {
                $0[true] {
                    $0 = +5%
                } = { "\(+$0[%]): Culture is \(em: culture.name)" }
            } else {
                $0[true] {
                    $0 = -75%
                } = { "\(+$0[%]): Culture is not \(em: culture.name)" }
            }
        }
    }
}

struct PopSnapshot: Sendable {
    let type: PopMetadata
    let state: Pop
    let stats: Pop.Stats
    let region: RegionalProperties
    let equity: Equity<LEI>.Statistics
    let mines: [MineID: MiningJobConditions]
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
        mine: MiningJobConditions
    ) {
        ul["Production per miner"] = (mine.factor * Double.init(base))[..3]
        ul[>] {
            $0["Base"] = base[/3]
        }

        ul["Mining efficiency"] = mine.factor[%1]
        ul[>] {
            switch self.state.type.occupation {
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
        let mil: Double = self.region.pops.free.mil.average

        ul[>] = "Base: \(em: MineMetadata.efficiencyPoliticians[%])"
        ul["Militancy of Free Population", +] = +(
            MineMetadata.efficiencyPoliticiansPerMilitancyPoint * mil
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
        self.explainNeeds(&ul, base: l, needsScalePerCapita: self.state.needsScalePerCapita.l)
    }
    private func explainNeeds(_ ul: inout TooltipInstructionEncoder, e: Int64) {
        self.explainNeeds(&ul, base: e, needsScalePerCapita: self.state.needsScalePerCapita.e)
    }
    private func explainNeeds(_ ul: inout TooltipInstructionEncoder, x: Int64) {
        self.explainNeeds(&ul, base: x, needsScalePerCapita: self.state.needsScalePerCapita.x)
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
extension PopSnapshot: LegalEntitySnapshot {
    func tooltipExplainPrice(
        _ line: InventoryLine,
        market: (segmented: LocalMarketSnapshot?, tradeable: WorldMarket.State?)
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
        case .m(let id):
            return self.state.mines[id.mine]?.out.tooltipExplainPrice(id.resource, market)
        }
    }
}
extension PopSnapshot {
    func tooltipAccount(_ account: Bank.Account) -> Tooltip? {
        let liquid: TurnDelta<Int64> = account.Δ
        let assets: TurnDelta<Int64> = self.state.Δ.vl + self.state.Δ.ve + self.state.Δ.vx
        let valuation: TurnDelta<Int64> = liquid + assets

        return .instructions {
            if case .Ward = self.state.type.stratum {
                let profit: ProfitMargins = self.state.profit
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
                let excluded: Int64 = self.state.spending.totalExcludingEquityPurchases
                $0["Welfare", +] = +?account.s[/3]
                $0[self.state.occupation.earnings, +] = +?account.r[/3]
                $0["Interest and dividends", +] = +?account.i[/3]

                $0["Market spending", +] = +?(account.b - excluded)[/3]
                $0["Stock sales", +] = +?account.j[/3]
                if case .Ward = self.state.type.stratum {
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
            $0["Active slaves", +] = self.state.Δ.active[/3]
            $0[>] {
                $0["Backgrounding", +] = +?(-self.state.mothballed)[/3]
                $0["Rehabilitation", +] = +?self.state.restored[/3]
                $0["Breeding", +] = +?self.state.created[/3]
            }
        }
    }
    func tooltipActiveHelp() -> Tooltip? {
        .instructions {
            let slaveBreedingEfficiency: Decimal = PopContext.slaveBreedingBase
                + self.region.modifiers.livestockBreedingEfficiency.value
            let slaveBreedingRate: Double = Double.init(
                slaveBreedingEfficiency
            ) * self.state.developmentRate(utilization: 1)

            $0["Breeding rate", +] = slaveBreedingRate[%2]
            $0[>] {
                $0["Profitability", +] = max(0, self.state.z.profitability)[%1]
                $0["Background population", +] = +?(
                    self.state.developmentRateVacancyFactor - 1
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

            let total: Int64 = self.state.z.total
            $0[>] = """
            There \(total == 1 ? "is" : "are") \(em: total[/3]) total \
            \(total == 1 ? "slave" : "slaves") of this type in this region
            """
        }
    }
    func tooltipVacant() -> Tooltip? {
        .instructions {
            $0["Backgrounded slaves", -] = self.state.Δ.vacant[/3]
            $0[>] {
                $0["Backgrounding", -] = +?self.state.mothballed[/3]
                $0["Rehabilitation", -] = +?(-self.state.restored)[/3]
                $0["Attrition", +] = +?(-self.state.destroyed)[/3]
            }
        }
    }
    func tooltipVacantHelp() -> Tooltip? {
        .instructions {
            let attrition: Double = self.state.attrition ?? 0

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
        .instructions {
            switch tier {
            case .l:
                let inputs: ResourceInputs = self.state.inventory.l
                $0["Life needs fulfilled"] = self.state.z.fl[%2]
                $0[>] {
                    $0["Market spending (amortized)", +] = inputs.valueConsumed[/3]
                    $0["Militancy", -] = +?PopContext.mil(fl: self.state.z.fl)[..3]
                    $0["Consciousness", -] = +?PopContext.con(fl: self.state.z.fl)[..3]
                }
            case .e:
                let inputs: ResourceInputs = self.state.inventory.e
                $0["Everyday needs fulfilled"] = self.state.z.fe[%2]
                $0[>] {
                    $0["Market spending (amortized)", +] = inputs.valueConsumed[/3]
                    $0["Militancy", -] = +?PopContext.mil(fe: self.state.z.fe)[..3]
                    $0["Consciousness", -] = +?PopContext.con(fe: self.state.z.fe)[..3]
                }
            case .x:
                let inputs: ResourceInputs = self.state.inventory.x
                $0["Luxury needs fulfilled"] = self.state.z.fx[%2]
                $0[>] {
                    $0["Market spending (amortized)", +] = inputs.valueConsumed[/3]
                    if let budget: Pop.Budget = self.state.budget, budget.investment > 0 {
                            $0["Investment budget", +] = budget.investment[/3]
                    }

                    $0["Militancy", -] = +?PopContext.mil(fx: self.state.z.fx)[..3]
                    $0["Consciousness", -] = +?PopContext.con(fx: self.state.z.fx)[..3]
                }
            }
        }
    }
    func tooltipOccupation() -> Tooltip? {
        let promotion: ConditionBreakdown = self.buildPromotionMatrix()
        let demotion: ConditionBreakdown = self.buildDemotionMatrix()

        let promotions: Int64 = promotion.output > 0
            ? .init(Double.init(self.state.z.active) * promotion.output * 30)
            : 0
        let demotions: Int64 = demotion.output > 0
            ? .init(Double.init(self.state.z.active) * demotion.output * 30)
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
            return self.state.inventory.l.tooltipDemand(
                resource,
                tier: self.type.l,
                details: self.explainNeeds(_:l:)
            )
        case .e(let resource):
            return self.state.inventory.e.tooltipDemand(
                resource,
                tier: self.type.e,
                details: self.explainNeeds(_:e:)
            )
        case .x(let resource):
            return self.state.inventory.x.tooltipDemand(
                resource,
                tier: self.type.x,
                details: self.explainNeeds(_:x:)
            )
        case .o(let resource):
            return self.state.inventory.out.tooltipSupply(
                resource,
                tier: self.type.output,
                details: self.explainProduction(_:base:)
            )
        case .m(let id):
            guard
            let miningConditions: MiningJobConditions = self.mines[id.mine] else {
                return nil
            }
            return self.state.mines[id.mine]?.out.tooltipSupply(
                id.resource,
                tier: miningConditions.output,
            ) {
                self.explainProduction(&$0, base: $1, mine: miningConditions)
            }
        }
    }
}
