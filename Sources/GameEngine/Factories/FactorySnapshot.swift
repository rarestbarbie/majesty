import D
import Fraction
import GameEconomy
import GameIDs
import GameRules
import GameState
import GameUI

struct FactorySnapshot: Sendable {
    let type: FactoryMetadata
    let state: Factory
    let region: RegionalProperties
    let productivity: Int64
    let workers: Workforce?
    let clerks: Workforce?
    let equity: Equity<LEI>.Statistics
    let cashFlow: CashFlowStatement
}
extension FactorySnapshot: LegalEntitySnapshot {
    func tooltipExplainPrice(
        _ line: InventoryLine,
        market: (segmented: LocalMarketSnapshot?, tradeable: WorldMarket.State?)
    ) -> Tooltip? {
        switch line {
        case .l(let id): return self.state.inventory.l.tooltipExplainPrice(id, market)
        case .e(let id): return self.state.inventory.e.tooltipExplainPrice(id, market)
        case .x(let id): return self.state.inventory.x.tooltipExplainPrice(id, market)
        case .o(let id): return self.state.inventory.out.tooltipExplainPrice(id, market)
        case .m: return nil
        }
    }
}
extension FactorySnapshot {
    private func explainProduction(_ ul: inout TooltipInstructionEncoder, base: Int64) {
        let productivity: Double = Double.init(self.productivity)
        let efficiency: Double = self.state.z.eo
        ul["Production per worker"] = (productivity * efficiency * Double.init(base))[..3]
        ul[>] {
            $0["Base"] = base[/3]
            $0["Productivity", +] = productivity[%2]
            $0["Efficiency", +] = +?(efficiency - 1)[%2]
        }
    }

    private func explainNeeds(_ ul: inout TooltipInstructionEncoder, x: Int64) {
        self.explainNeeds(&ul, base: x, unit: "level")
    }
    private func explainNeeds(_ ul: inout TooltipInstructionEncoder, base: Int64) {
        self.explainNeeds(&ul, base: base, unit: "worker")
    }
    private func explainNeeds(
        _ ul: inout TooltipInstructionEncoder,
        base: Int64,
        unit: String
    ) {
        let productivity: Double = Double.init(self.productivity)
        let efficiency: Double = self.state.z.ei
        ul["Demand per \(unit)"] = (productivity * efficiency * Double.init(base))[..3]
        ul[>] {
            $0["Base"] = base[/3]
            $0["Productivity", +] = productivity[%2]
            $0["Efficiency", -] = +?(efficiency - 1)[%2]
        }
    }
}
extension FactorySnapshot {
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
                $0["Salaries", +] = +?(-self.state.spending.salaries)[/3]
                $0["Wages", +] = +?(-self.state.spending.wages)[/3]
                $0["Interest and dividends", +] = +?(-self.state.spending.dividend)[/3]
                $0["Stock buybacks", +] = (-self.state.spending.buybacks)[/3]
                if account.e > 0 {
                    $0["Market capitalization", +] = +account.e[/3]
                }
            }
        }
    }

    func tooltipWorkers() -> Tooltip? {
        guard let workforce: Workforce = self.workers else {
            return nil
        }
        return .instructions {
            $0[self.type.workers.unit.plural] = workforce.count[/3] / workforce.limit
            workforce.explainChanges(&$0)
        }
    }
    func tooltipWorkersHelp() -> Tooltip? {
        return .instructions {
            $0["Current wage"] = self.state.Δ.wn[/3]
            if  let _: Int = self.state.z.wf {
                $0[>] = """
                This factory does not offer a \(em: "competitive wage"), which is causing it \
                to have difficulty hiring workers
                """
            } else {
                $0[>] = """
                The wages paid to workers are \(em: "sticky") and will only decrease if the \
                factory goes bankrupt
                """
            }
        }
    }
    func tooltipClerks() -> Tooltip? {
        guard
        let clerks: Workforce = self.clerks else {
            return nil
        }
        return .instructions {
            $0[self.type.clerks.unit.plural] = clerks.count[/3] / clerks.limit
            $0[>] {
                let bonus: Double = FactoryContext.efficiencyBonusFromClerks(
                    fk: self.state.z.fk
                )
                $0["Input efficiency", -] = +(-bonus)[%2]
            }

            clerks.explainChanges(&$0)
        }
    }
    func tooltipClerksHelp() -> Tooltip? {
        guard
        let workers: Workforce = self.workers,
        let clerks: Workforce = self.clerks else {
            return nil
        }
        return .instructions {
            $0["Current salary"] = self.state.Δ.wn[/3]

            let clerkHorizon: Int64 = self.type.clerkHorizon(for: workers.count)
            if case .active(let budget)? = self.state.budget, budget.fk < 1 {
                $0[>] = """
                Due to the present \(em: "skills shortage"), this factory is only employing \
                \(neg: (100 * budget.fk)[..1]) percent of its maximum number of clerks
                """
            }

            $0[>] = """
            At most \(
                clerkHorizon[/3],
                style: clerks.count <= clerkHorizon ? .em : .neg
            ) clerks may contribute to this factory
            """
            $0[>] = """
            Clerks make factories more efficient, but are also much harder to fire
            """
        }
    }

    func tooltipNeeds(
        _ tier: ResourceTierIdentifier
    ) -> Tooltip? {
        .instructions {
            switch tier {
            case .l:
                let inputs: ResourceInputs = self.state.inventory.l
                $0["Materials fulfilled"] = self.state.z.fl[%2]
                $0[>] {
                    $0["Market spending (amortized)", +] = inputs.valueConsumed[/3]
                    $0["Efficiency", -] = +?(self.state.z.ei - 1)[%2]
                }
                $0[>] = """
                Factories that lack materials will not produce anything
                """
            case .e:
                let inputs: ResourceInputs = self.state.inventory.e
                $0["Corporate supplies"] = self.state.z.fe[%2]
                $0[>] {
                    $0["Market spending (amortized)", +] = inputs.valueConsumed[/3]
                    $0["Efficiency", -] = +?(self.state.z.ei - 1)[%2]
                }

                let bonus: Double = FactoryContext.efficiencyBonusFromCorporate(
                    fe: self.state.z.fe
                )

                $0[>] = bonus > 0 ? """
                Today this factory saved \(pos: bonus[%1]) on all inputs
                """ : """
                Factories that purchase all of their corporate supplies are more efficient
                """

                if case .active(let budget)? = self.state.budget, budget.fe < 1 {
                    $0[>] = """
                    Due to high \(em: "compliance costs"), this factory is only purchasing \
                    \(neg: (100 * budget.fe)[..1]) percent of its corporate supplies
                    """
                }
            case .x:
                let inputs: ResourceInputs = self.state.inventory.x
                $0["Capital expenditures"] = self.state.z.fx[%2]
                $0[>] {
                    $0["Market spending (amortized)", +] = inputs.valueConsumed[/3]
                    $0["Efficiency", -] = +?(self.state.z.ei - 1)[%2]
                }
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
                tier: self.type.materials,
                details: self.explainNeeds(_:base:)
            )
        case .e(let resource):
            return self.state.inventory.e.tooltipDemand(
                resource,
                tier: self.type.corporate,
                details: self.explainNeeds(_:base:)
            )
        case .x(let resource):
            return self.state.inventory.x.tooltipDemand(
                resource,
                tier: self.type.expansion,
                details: self.explainNeeds(_:x:)
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


    func tooltipSize() -> Tooltip {
        .instructions {
            $0["Effective size"] = self.state.size.area?[/3]
            $0["Growth progress"] = self.state.size.growthProgress[/0]
                / Factory.Size.growthRequired

            if  let liquidation: FactoryLiquidation = self.state.liquidation {
                let shareCount: Int64 = self.equity.shareCount
                $0[>] = """
                This factory has been in bankruptcy proceedings since \
                \(em: liquidation.started[.phrasal_US]) and there \(
                    shareCount == 1 ? "is" : "are"
                ) \(neg: shareCount) \(
                    shareCount == 1 ? "share" : "shares"
                ) left to liquidate
                """
            } else {
                $0[>] = """
                Doubling the factory level will quadruple its capacity
                """
            }
        }
    }

    func tooltipSummarizeEmployees(_ stratum: PopStratum) -> Tooltip? {
        let workforce: Workforce
        let type: PopOccupation

        if case .Worker = stratum,
            let workers: Workforce = self.workers {
            workforce = workers
            type = self.type.workers.unit
        } else if
            let clerks: Workforce = self.clerks {
            workforce = clerks
            type = self.type.clerks.unit
        } else {
            return nil
        }

        return .instructions {
            $0[type.plural] = workforce.count[/3] / workforce.limit
            workforce.explainChanges(&$0)
        }
    }
}
