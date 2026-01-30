import D
import GameEconomy
import GameRules
import GameState
import GameIDs
import GameUI

struct BuildingSnapshot: BuildingProperties, Sendable {
    let metadata: BuildingMetadata
    let stats: Building.Stats
    let region: RegionalProperties

    let id: BuildingID
    let tile: Address
    let type: BuildingType
    let mothballed: Int64
    let destroyed: Int64
    let restored: Int64
    let created: Int64
    let inventory: InventorySnapshot
    let spending: Building.Spending
    let budget: Building.Budget?
    let y: Building.Dimensions
    let z: Building.Dimensions

    let equity: Equity<LEI>.Snapshot
}
extension BuildingSnapshot {
    init(
        metadata: BuildingMetadata,
        stats: Building.Stats,
        region: RegionalProperties,
        equity: Equity<LEI>.Statistics,
        state: Building
    ) {
        self.init(
            metadata: metadata,
            stats: stats,
            region: region,
            id: state.id,
            tile: state.tile,
            type: state.type,
            mothballed: state.mothballed,
            destroyed: state.destroyed,
            restored: state.restored,
            created: state.created,
            inventory: .building(state),
            spending: state.spending,
            budget: state.budget,
            y: state.y,
            z: state.z,
            equity: .init(equity: state.equity, stats: equity)
        )
    }
}
extension BuildingSnapshot: LegalEntitySnapshot, BusinessSnapshot {}
extension BuildingSnapshot {
    private func explainProduction(_ ul: inout TooltipInstructionEncoder, base: Int64) {
        ul["Production per facility"] = base[/3]
    }
    private func explainNeeds(
        _ ul: inout TooltipInstructionEncoder, base: Int64) {
        let efficiency: Double = self.z.ei
        ul["Demand per facility"] = (efficiency * Double.init(base))[..3]
        ul[>] {
            $0["Base"] = base[/3]
            $0["Efficiency", -] = +?(efficiency - 1)[%2]
        }
    }
}
extension BuildingSnapshot {
    func tooltipAccount(_ account: Bank.Account) -> Tooltip {
        .instructions {
            self.explain(statement: self.stats.financial, account: account, tooltip: &$0)
        }
    }
    func tooltipActive() -> Tooltip {
        .instructions {
            $0["Active facilities", +] = self.Δ.active[/3]
            $0[>] {
                $0["Backgrounding", +] = +?(-self.mothballed)[/3]
                $0["Restoration", +] = +?self.restored[/3]
                $0["Development", +] = +?self.created[/3]
            }
        }
    }
    func tooltipActiveHelp() -> Tooltip {
        .instructions {
            let developmentRate: Double = self.developmentRate(
                utilization: self.stats.utilization
            )
            $0["Developer attraction", +] = developmentRate[%2]
            $0[>] {
                $0["Profitability", +] = max(0, self.z.profitability)[%1]
                $0["Vacancy rate", +] = +?(self.developmentRateVacancyFactor - 1)[%2]
                $0["Unsold inventory", +] = +?(self.stats.utilization - 1)[%2]
            }

            let total: Int64 = self.z.total
            $0[>] = """
            There \(total == 1 ? "is" : "are") \(em: total[/3]) total \
            \(total == 1 ? "facility" : "facilities") in this region
            """
        }
    }
    func tooltipVacant() -> Tooltip {
        .instructions {
            $0["Vacant facilities", -] = self.Δ.vacant[/3]
            $0[>] {
                $0["Backgrounding", -] = +?self.mothballed[/3]
                $0["Restoration", -] = +?(-self.restored)[/3]
                $0["Attrition", +] = +?(-self.destroyed)[/3]
            }
        }
    }
    func tooltipVacantHelp() -> Tooltip {
        .instructions {
            $0["Vacancy rate", -] = self.Δ.vacancy[%1]
            $0[>] {
                $0["Investor attraction", +] = +?(
                    self.developmentRateVacancyFactor - 1
                )[%2]
            }

            $0[>] = """
            Vacant buildings depress investment in new construction and can also encourage \
            \(em: "crime")
            """
        }
    }
    func tooltipNeeds(_ tier: ResourceTierIdentifier) -> Tooltip {
        .instructions {
            var valueConsumed: Int64 { self.inventory.valueConsumed(tier: tier) }

            switch tier {
            case .l:
                $0["Operational needs fulfilled"] = self.z.fl[%2]
                $0[>] {
                    $0["Market spending (amortized)", +] = valueConsumed[/3]
                }
                $0[>] = """
                Only \(em: "active") facilities consume operational resources
                """
            case .e:
                $0["Maintenance needs fulfilled"] = self.z.fe[%2]
                $0[>] {
                    $0["Restoration", +] = self.restoration.map { +$0[%2] }
                    $0["Attrition", +] = self.attrition.map { +(-$0)[%2] }
                    $0["Market spending (amortized)", +] = valueConsumed[/3]
                }
                $0[>] = """
                All facilities consume maintenance resources, even when \(em: "backgrounded")
                """
            case .x:
                $0["Development needs fulfilled"] = self.z.fx[%2]
            }
        }
    }
    func tooltipResourceIO(
        _ line: InventoryLine,
    ) -> Tooltip? {
        switch line {
        case .l(let resource):
            return self.inventory[.l(resource)]?.tooltipDemand(
                tier: self.metadata.operations,
                details: self.explainNeeds(_:base:)
            )
        case .e(let resource):
            return self.inventory[.e(resource)]?.tooltipDemand(
                tier: self.metadata.maintenance,
                details: self.explainNeeds(_:base:)
            )
        case .x(let resource):
            return self.inventory[.x(resource)]?.tooltipDemand(
                tier: self.metadata.development,
                details: self.explainNeeds(_:base:)
            )

        case .o(let resource):
            return self.inventory[.o(resource)]?.tooltipSupply(
                tier: self.metadata.output,
                details: self.explainProduction(_:base:)
            )

        case .m:
            return nil
        }
    }
}
