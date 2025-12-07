import D
import GameEconomy
import GameRules
import GameState
import GameIDs
import GameUI

struct BuildingSnapshot: Sendable {
    let type: BuildingMetadata
    let state: Building
    let stats: Building.Stats
    let region: RegionalProperties
    let equity: Equity<LEI>.Statistics
}
extension BuildingSnapshot {
    private func explainProduction(_ ul: inout TooltipInstructionEncoder, base: Int64) {
        ul["Production per facility"] = base[/3]
    }
    private func explainNeeds(
        _ ul: inout TooltipInstructionEncoder, base: Int64) {
        let efficiency: Double = self.state.z.ei
        ul["Demand per facility"] = (efficiency * Double.init(base))[..3]
        ul[>] {
            $0["Base"] = base[/3]
            $0["Efficiency", -] = +?(efficiency - 1)[%2]
        }
    }
}
extension BuildingSnapshot: LegalEntitySnapshot {
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
        case .m:
            return nil
        }
    }
}
extension BuildingSnapshot {
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
        }
    }
    func tooltipActiveHelp() -> Tooltip? {
        .instructions {
            let developmentRate: Double = self.state.developmentRate(
                utilization: self.stats.utilization
            )
            $0["Developer attraction", +] = developmentRate[%2]
            $0[>] {
                $0["Profitability", +] = max(0, self.state.z.profitability)[%1]
                $0["Vacancy rate", +] = +?(self.state.developmentRateVacancyFactor - 1)[%2]
                $0["Unsold inventory", +] = +?(self.stats.utilization - 1)[%2]
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
    func tooltipVacantHelp() -> Tooltip? {
        .instructions {
            $0["Vacancy rate", -] = self.state.Δ.vacancy[%1]
            $0[>] {
                $0["Investor attraction", +] = +?(
                    self.state.developmentRateVacancyFactor - 1
                )[%2]
            }

            $0[>] = """
            Vacant buildings depress investment in new construction and can also encourage \
            \(em: "crime")
            """
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
                    $0["Restoration", +] = self.state.restoration.map { +$0[%2] }
                    $0["Attrition", +] = self.state.attrition.map { +(-$0)[%2] }
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
    func tooltipResourceIO(
        _ line: InventoryLine,
    ) -> Tooltip? {
        switch line {
        case .l(let resource):
            return self.state.inventory.l.tooltipDemand(
                resource,
                tier: self.type.operations,
                details: self.explainNeeds(_:base:)
            )
        case .e(let resource):
            return self.state.inventory.e.tooltipDemand(
                resource,
                tier: self.type.maintenance,
                details: self.explainNeeds(_:base:)
            )
        case .x(let resource):
            return self.state.inventory.x.tooltipDemand(
                resource,
                tier: self.type.development,
                details: self.explainNeeds(_:base:)
            )

        case .o(let resource):
            return self.state.inventory.out.tooltipSupply(
                resource,
                tier: self.type.output,
                details: self.explainProduction(_:base:)
            )

        case .m:
            return nil
        }
    }
}
