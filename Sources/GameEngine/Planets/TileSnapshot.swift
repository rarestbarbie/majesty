import D
import Fraction
import GameIDs
import GameRules
import GameUI

struct TileSnapshot: Differentiable, Identifiable, Sendable {
    let metadata: TileMetadata
    let id: Address
    let type: TileType
    let name: String?

    let history: [Tile.Aggregate]
    let country: DiplomaticAuthority?
    let y: Tile.Interval
    let z: Tile.Interval
}
extension TileSnapshot {
    private func aggregate<Crosstab, Value>(
        where crosstab: Crosstab,
        among totals: [EconomicLedger.Regional<Crosstab>: Value],
        worldContribution: (Value) -> Int64,
        localContribution: (Value) -> Int64
    ) -> (world: Int64, local: Int64, localExcluded: Int64) {
        totals.reduce(into: (0, 0, 0)) {
            if  $1.key.crosstab == crosstab {
                let worldContribution: Int64 = worldContribution($1.value)
                if  worldContribution > 0 {
                    $0.world += worldContribution
                }
            }
            if  $1.key.location == self.id {
                let localContribution: Int64 = localContribution($1.value)
                if  localContribution > 0 {
                    $0.local += localContribution
                } else {
                    $0.localExcluded += localContribution
                }
            }
        }
    }
    private func aggregate<Crosstab>(
        where crosstab: Crosstab,
        among totals: [EconomicLedger.Regional<Crosstab>: Int64],
    ) -> (world: Int64, local: Int64, localExcluded: Int64) {
        self.aggregate(
            where: crosstab,
            among: totals,
            worldContribution: { $0 },
            localContribution: { $0 }
        )
    }
}
extension TileSnapshot {
    func tooltip(
        _ layer: PlanetMapLayer,
    ) -> Tooltip? {
        /// average across sexes
        let incomeElite: Delta<EconomicLedger.IncomeMetrics> = self.Δ.stats.incomeElite.all
        let incomeUpper: Delta<EconomicLedger.IncomeMetrics> = self.Δ.stats.incomeUpper.all
        let incomeLower: Delta<EconomicLedger.IncomeMetrics> = self.Δ.stats.incomeLower.all
        let incomeAllFree: Delta<EconomicLedger.IncomeMetrics> = incomeElite
            + incomeUpper
            + incomeLower

        return .instructions(style: .borderless) {
            switch layer {
            case .Terrain:
                $0[>] = "\(self.metadata.ecology.title) (\(self.metadata.geology.title))"

            case .Population:
                $0["Population", +] = self.Δ.stats.voters.count[/3]
                $0[>] {
                    $0["Elites", +] = incomeElite.count[/3]
                    $0["Clerks", +] = incomeUpper.count[/3]
                    $0["Workers", +] = incomeLower.count[/3]
                    $0["Enslaved", +] = self.Δ.stats.slaves.count[/3]
                }

            case .AverageMilitancy:
                $0["Average militancy", -] = incomeAllFree.μ.mil[..2]
                $0[>] {
                    $0["Elites", -] = incomeElite.μ.mil[..2]
                    $0["Clerks", -] = incomeUpper.μ.mil[..2]
                    $0["Workers", -] = incomeLower.μ.mil[..2]
                }
                if  let mil: Double = self.z.stats.slaves.μ.mil.defined {
                    $0[>] = """
                    The average militancy of the slave population is \(
                        mil[..2],
                        style: mil > 1.0 ? .neg : .em
                    )
                    """
                }
            case .AverageConsciousness:
                $0["Average consciousness", -] = incomeAllFree.μ.con[..2]
                $0[>] {
                    $0["Elites", -] = incomeElite.μ.con[..2]
                    $0["Clerks", -] = incomeUpper.μ.con[..2]
                    $0["Workers", -] = incomeLower.μ.con[..2]
                }
                if  let con: Double = self.z.stats.slaves.μ.con.defined {
                    $0[>] = """
                    The average consciousness of the slave population is \(
                        con[..2],
                        style: con > 1.0 ? .neg : .em
                    )
                    """
                }
            }

            if let name: String = self.name {
                $0[>] = "\(name)"
            }
        }
    }
}
extension TileSnapshot {
    func tooltipPopRace(
        in context: GameUI.CacheContext,
        id: CultureID
    ) -> Tooltip? {
        /// note: capital metrics are currently only tracked for free pops
        guard
        let culture: Culture = context.rules.pops.cultures[id],
        let metrics: Delta<EconomicLedger.CapitalMetrics> = context.ledger.Δ.economy.racial[
            self.id / id
        ] else {
            return nil
        }

        guard
        let share: Delta<Double> = metrics.count.percentage(
            of: self.Δ.stats.voters.count
        ) else {
            return nil
        }

        return .instructions(style: .borderless) {
            $0[culture.name, +] = share[%3]
            $0[>] {
                $0["GNP per-capita", +] = metrics.μ.gnpContribution[/3..2]
                $0["Average militancy", -] = metrics.μ.mil[/3..2]
                $0["Average consciousness", -] = metrics.μ.con[/3..2]
            }
            $0[>] = """
            There are \(em: metrics.z.count[/3]) people of the \(em: culture.name) race in \
            \(self.name ?? "this region")
            """
            $0[>] = """
            The Gross National Product (GNP) counts all income earned by people of this race, \
            including unrealized capital gains
            """
        }
    }
    func tooltipPopOccupation(
        in context: GameUI.CacheContext,
        id: PopOccupation
    ) -> Tooltip? {
        guard
        let row: Delta<EconomicLedger.LaborMetrics> = context.ledger.Δ.economy.labor[
            self.id / id
        ] else {
            return nil
        }

        let total: Delta<Int64> = self.Δ.stats.voters.count
        guard
        let share: Delta<Double> = row.count.percentage(of: total) else {
            return nil
        }

        return .instructions(style: .borderless) {
            $0[id.plural, +] = share[%3]
            $0[>] {
                $0["Unemployment rate", -] = row.unemployed.percentage(of: row.count)?[%3]
            }
        }
    }
}
extension TileSnapshot {
    func tooltipGDP(
        in context: GameUI.CacheContext
    ) -> Tooltip {
        .instructions {
            $0["GDP", +] = self.Δ.stats.gdp[/3]

            let average: Delta<Mean<Tile.Stats>> = self.Δ.stats._μFree
            $0[>] {
                $0["GDP per capita", +] = average.gdp[/3..2]
                $0["GNP per capita", +] = average.gnp[/3..2]
            }

            /// average across sexes
            let incomeElite: Delta<EconomicLedger.IncomeMetrics> = self.Δ.stats.incomeElite.all
            let incomeUpper: Delta<EconomicLedger.IncomeMetrics> = self.Δ.stats.incomeUpper.all
            let incomeLower: Delta<EconomicLedger.IncomeMetrics> = self.Δ.stats.incomeLower.all
            $0["Income per capita", +] = (
                incomeElite + incomeUpper + incomeLower
            ).μ.incomeTotal[/3..2]

            $0[>] {
                $0["Elites", +] = incomeElite.μ.incomeTotal[/3..2]
                $0["Clerks", +] = incomeUpper.μ.incomeTotal[/3..2]
                $0["Workers", +] = incomeLower.μ.incomeTotal[/3..2]
            }
        }
    }
    func tooltipIndustry(
        in context: GameUI.CacheContext,
        id: EconomicLedger.Industry,
    ) -> Tooltip? {
        guard
        let country: DiplomaticAuthority = self.country,
        let value: Int64 = context.ledger.z.economy.gdp[self.id / id] else {
            return nil
        }

        let total: (world: Int64, local: Int64, localExcluded: Int64) = self.aggregate(
            where: id,
            among: context.ledger.z.economy.gdp,
            worldContribution: { $0 },
            localContribution: { $0 }
        )

        return .instructions(style: .borderless) {
            $0[context.rules.name(id)] = (
                total.local > 0 ? Double.init(value %/ total.local) : 0
            )[%2]
            $0[>] {
                $0["Estimated GDP contribution (\(country.currency.name))", +] = +?value[/3]
            }

            if case .artisan = id {
                $0[>] = """
                All of the income from self-employment counts towards GDP
                """
            } else {
                $0[>] = """
                Only income left over after subtracting costs (except for labor) counts \
                towards GDP
                """
            }
            if  total.localExcluded < 0 {
                $0[>] = """
                \(neg: +total.localExcluded[/3]) \(country.currency.name) of business losses \
                are excluded from percentage calculations
                """
            }
        }
    }

    func tooltipResourceProduced(
        in context: GameUI.CacheContext,
        id resource: Resource,
    ) -> Tooltip? {
        guard
        let country: DiplomaticAuthority = self.country,
        let traded: TradeVolume = context.ledger.z.economy.trade[self.id / resource] else {
            return nil
        }

        let total: (world: Int64, local: Int64, localExcluded: Int64) = self.aggregate(
            where: resource,
            among: context.ledger.z.economy.trade,
            worldContribution: \.unitsProduced,
            localContribution: \.valueProduced
        )

        let resource: ResourceMetadata = context.rules.resources[resource]
        let value: Int64 = traded.valueProduced
        let units: Int64 = traded.unitsProduced

        return .instructions(style: .borderless) {
            $0[resource.title] = (total.local > 0 ? Double.init(value %/ total.local) : 0)[%2]
            $0[>] {
                $0["Estimated market value (\(country.currency.name))", +] = +?value[/3]
                if !resource.local {
                    $0 += traded
                }
            }

            let share: Double = .init(units %/ max(total.world, 1))
            $0[>] = """
            Today this region produced \(em: units[/3]) units of \(em: resource.title) \
            comprising \(em: share[%2]) of world production
            """
        }
    }

    func tooltipResourceConsumed(
        in context: GameUI.CacheContext,
        id resource: Resource,
    ) -> Tooltip? {
        guard
        let country: DiplomaticAuthority = self.country,
        let traded: TradeVolume = context.ledger.z.economy.trade[self.id / resource] else {
            return nil
        }

        let total: (world: Int64, local: Int64, localExcluded: Int64) = self.aggregate(
            where: resource,
            among: context.ledger.z.economy.trade,
            worldContribution: \.unitsConsumed,
            localContribution: \.valueConsumed
        )

        let resource: ResourceMetadata = context.rules.resources[resource]
        let value: Int64 = traded.valueConsumed
        let units: Int64 = traded.unitsConsumed

        return .instructions(style: .borderless) {
            $0[resource.title] = (total.local > 0 ? Double.init(value %/ total.local) : 0)[%2]
            $0[>] {
                $0["Estimated market value (\(country.currency.name))", -] = +?value[/3]
                if !resource.local {
                    $0 += traded
                }
            }

            let share: Double = .init(units %/ max(total.world, 1))
            $0[>] = """
            Today this region consumed \(em: units[/3]) units of \(em: resource.title) \
            comprising \(em: share[%2]) of world consumption
            """
        }
    }
}
extension TileSnapshot {
    func tooltipResourceOrigin(mine: MineSnapshot, ledger: GameLedger.Interval) -> Tooltip {
        .instructions {
            $0[mine.metadata.miner.plural, +] = mine.miners.count[/3] / mine.miners.limit
            if  mine.z.parcels > 1 {
                $0[>] {
                    $0["Parcels"] = mine.z.parcels[/3]
                }
            }
            $0["Today’s change", +] = +(mine.miners.count - mine.miners.before)[/3]
            $0[>] {
                // only elide fired, it’s annoying when the lines below jump around
                $0["Hired", +] = +mine.miners.hired[/3]
                $0["Fired", +] = +?(-mine.miners.fired)[/3]
                $0["Quit", +] = +(-mine.miners.quit)[/3]
            }
            let h²: Delta<Double> = .init(
                y: MineMetadata.h²(
                    h: mine.metadata.h(tile: self.y.stats, yield: mine.y.yieldPerMiner)
                ),
                z: MineMetadata.h²(
                    h: mine.metadata.h(tile: self.z.stats, yield: mine.z.yieldPerMiner)
                )
            )
            let h: Delta<Double> = MineContext.h0 * h²
            $0["Hiring rate", +] = h[%2]
            $0[>] {
                $0["Base"] = MineContext.h0[%2]
                $0["Relative yield", +] = +?(h².z - 1)[%2]
            }
            if  mine.metadata.decay {
                $0["Estimated deposits"] = mine.Δ.size[/3]
                $0[>] {
                    $0["Estimated yield", (+)] = mine.Δ.yieldBase[/3..2]
                }
                if  let yieldRank: Int = mine.z.yieldRank,
                    let (chance, spawn): (Fraction, SpawnWeight) = mine.metadata.chance(
                        tile: self.type.geology,
                        size: mine.z.size,
                        yieldRank: yieldRank
                    ),
                    let miners: EconomicLedger.LaborMetrics = ledger.economy.labor[
                        self.id / .Miner
                    ],
                    let fromWorkers: Fraction = miners.mineExpansionFactor {
                    let fromDeposit: Double = .init(
                        mine.metadata.scale %/ (mine.metadata.scale + mine.z.size)
                    )
                    let fromWorkers: Double = .init(fromWorkers)
                    let fromRank: Double = MineMetadata.yieldRankExpansionFactor(
                        yieldRank
                    ).map(
                        Double.init(_:)
                    ) ?? 0.0
                    let chance: Double = Double.init(chance) * fromWorkers
                    $0["Chance to expand mine", (+)] = chance[%2]
                    $0[>] {
                        $0["Base"] = spawn.rate.value[%]
                        $0["From yield rank", (+)] = +?(fromRank - 1)[%0]
                        $0["From size of deposit", (+)] = (fromDeposit - 1)[%2]
                        $0["From unemployed miners", (+)] = fromWorkers[%2]
                    }
                }
                if  let expanded: Mine.Expansion = mine.last {
                    $0[>] = """
                    We recently unearthed a deposit of size \(em: expanded.size[/3]) on \
                    \(em: expanded.date[.phrasal_US])
                    """
                }
            }

            $0[>] = "\(mine.metadata.title)"
        }
    }
}
