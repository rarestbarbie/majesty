import D
import Fraction
import GameEconomy
import GameIDs
import GameRules
import GameState
import GameUI

struct FactorySnapshot: FactoryProperties, Sendable {
    let metadata: FactoryMetadata
    let stats: Factory.Stats
    let region: RegionalProperties
    let workers: Workforce?
    let clerks: Workforce?

    let id: FactoryID
    let tile: Address
    let type: FactoryType
    let size: Factory.Size

    let liquidation: FactoryLiquidation?

    let inventory: InventorySnapshot
    let spending: Factory.Spending
    /// This is part of the persistent state, because it is only computed during a turn, and
    /// we want the budget info to be available for inspection when loading a save.
    let budget: Factory.Budget?
    let y: Factory.Dimensions
    let z: Factory.Dimensions

    let equity: Equity<LEI>.Snapshot
}
extension FactorySnapshot {
    init(
        metadata: FactoryMetadata,
        stats: Factory.Stats,
        region: RegionalProperties,
        workers: Workforce?,
        clerks: Workforce?,
        equity: Equity<LEI>.Statistics,
        state: Factory
    ) {
        self.init(
            metadata: metadata,
            stats: stats,
            region: region,
            workers: workers,
            clerks: clerks,
            id: state.id,
            tile: state.tile,
            type: state.type,
            size: state.size,
            liquidation: state.liquidation,
            inventory: .factory(state),
            spending: state.spending,
            budget: state.budget,
            y: state.y,
            z: state.z,
            equity: .init(equity: state.equity, stats: equity)
        )
    }
}
extension FactorySnapshot: LegalEntitySnapshot {}
extension FactorySnapshot {
    private func explainProduction(_ ul: inout TooltipInstructionEncoder, base: Int64) {
        let productivity: Double = Double.init(self.stats.productivity)
        let efficiency: Double = self.z.eo
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
        let productivity: Double = Double.init(self.stats.productivity)
        let efficiency: Double = self.z.ei
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
        let profit: ProfitMargins = self.stats.profit
        let liquid: Delta<Int64> = account.Δ
        let assets: Delta<Int64> = self.Δ.vl + self.Δ.ve + self.Δ.vx

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
                let excluded: Int64 = self.spending.totalExcludingEquityPurchases
                $0["Market spending", +] = +(account.b + excluded)[/3]
                $0["Market earnings", +] = +?account.r[/3]
                $0["Subsidies", +] = +?account.s[/3]
                $0["Salaries", +] = +?(-self.spending.salaries)[/3]
                $0["Wages", +] = +?(-self.spending.wages)[/3]
                $0["Interest and dividends", +] = +?(-self.spending.dividend)[/3]
                $0["Stock buybacks", +] = (-self.spending.buybacks)[/3]
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
            $0[self.metadata.workers.unit.plural] = workforce.count[/3] / workforce.limit
            workforce.explainChanges(&$0)
        }
    }
    func tooltipWorkersHelp() -> Tooltip? {
        return .instructions {
            $0["Current wage"] = self.Δ.wn[/3]
            if  let _: Int = self.z.wf {
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
            $0[self.metadata.clerks.unit.plural] = clerks.count[/3] / clerks.limit
            $0[>] {
                let bonus: Double = FactoryContext.efficiencyBonusFromClerks(
                    fk: self.z.fk
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
            $0["Current salary"] = self.Δ.wn[/3]

            let clerkHorizon: Int64 = self.metadata.clerkHorizon(for: workers.count)
            if case .active(let budget)? = self.budget, budget.fk < 1 {
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
            let valueConsumed: Int64 = self.inventory.valueConsumed(tier: tier)
            switch tier {
            case .l:
                $0["Materials fulfilled"] = self.z.fl[%2]
                $0[>] {
                    $0["Market spending (amortized)", +] = valueConsumed[/3]
                    $0["Efficiency", -] = +?(self.z.ei - 1)[%2]
                }
                $0[>] = """
                Factories that lack materials will not produce anything
                """
            case .e:
                $0["Corporate supplies"] = self.z.fe[%2]
                $0[>] {
                    $0["Market spending (amortized)", +] = valueConsumed[/3]
                    $0["Efficiency", -] = +?(self.z.ei - 1)[%2]
                }

                let bonus: Double = FactoryContext.efficiencyBonusFromCorporate(
                    fe: self.z.fe
                )

                $0[>] = bonus > 0 ? """
                Today this factory saved \(pos: bonus[%1]) on all inputs
                """ : """
                Factories that purchase all of their corporate supplies are more efficient
                """

                if case .active(let budget)? = self.budget, budget.fe < 1 {
                    $0[>] = """
                    Due to high \(em: "compliance costs"), this factory is only purchasing \
                    \(neg: (100 * budget.fe)[..1]) percent of its corporate supplies
                    """
                }
            case .x:
                $0["Capital expenditures"] = self.z.fx[%2]
                $0[>] {
                    $0["Market spending (amortized)", +] = valueConsumed[/3]
                    $0["Efficiency", -] = +?(self.z.ei - 1)[%2]
                }
            }
        }
    }

    func tooltipResourceIO(
        _ line: InventoryLine,
    ) -> Tooltip? {
        switch line {
        case .l(let resource):
            return self.inventory[.l(resource)]?.tooltipDemand(
                tier: self.metadata.materials,
                details: self.explainNeeds(_:base:)
            )
        case .e(let resource):
            return self.inventory[.e(resource)]?.tooltipDemand(
                tier: self.metadata.corporate,
                details: self.explainNeeds(_:base:)
            )
        case .x(let resource):
            return self.inventory[.x(resource)]?.tooltipDemand(
                tier: self.metadata.expansion,
                details: self.explainNeeds(_:x:)
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


    func tooltipSize() -> Tooltip {
        .instructions {
            $0["Effective size"] = self.size.area?[/3]
            $0["Growth progress"] = self.size.growthProgress[/0]
                / Factory.Size.growthRequired

            if  let liquidation: FactoryLiquidation = self.liquidation {
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
            type = self.metadata.workers.unit
        } else if
            let clerks: Workforce = self.clerks {
            workforce = clerks
            type = self.metadata.clerks.unit
        } else {
            return nil
        }

        return .instructions {
            $0[type.plural] = workforce.count[/3] / workforce.limit
            workforce.explainChanges(&$0)
        }
    }
}
