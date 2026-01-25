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
    var pops: PopulationStats { self.z.stats.pops }
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
        let pops: Delta<PopulationStats> = self.Δ.stats.pops
        return .instructions(style: .borderless) {
            switch layer {
            case .Terrain:
                $0[>] = "\(self.metadata.ecology.title) (\(self.metadata.geology.title))"

            case .Population:
                $0["Population", +] = pops.free.total[/3]
                $0[>] {
                    $0["Free", +] = pops.free.total[/3]
                    $0["Enslaved", +] = pops.enslaved.total[/3]
                }

            case .AverageMilitancy:
                let free: Delta<Double> = pops.free.μ.mil
                $0["Average militancy", -] = free[..2]
                if  let mil: Double = self.z.stats.pops.enslaved.μ.mil.defined {
                    $0[>] = """
                    The average militancy of the slave population is \(
                        mil[..2],
                        style: mil > 1.0 ? .neg : .em
                    )
                    """
                }
            case .AverageConsciousness:
                let free: Delta<Double> = pops.free.μ.con
                $0["Average consciousness", -] = free[..2]
                if  let con: Double = self.z.stats.pops.enslaved.μ.con.defined {
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
    func tooltip(culture: Culture) -> Tooltip? {
        let free: Delta<Int64>? = self.Δ.stats.pops.free.cultures[culture.id]
        let enslaved: Delta<Int64>? = self.Δ.stats.pops.enslaved.cultures[culture.id]

        let count: Delta<Int64>
        let total: Delta<Int64>

        if  let free: Delta<Int64> {
            count = free
            total = self.Δ.stats.pops.free.total
        } else if
            let enslaved: Delta<Int64> {
            count = enslaved
            total = self.Δ.stats.pops.enslaved.total
        } else {
            return nil
        }

        guard
        let share: Delta<Double> = count.percentage(of: total) else {
            return nil
        }

        return .instructions(style: .borderless) {
            $0[culture.name, +] = share[%3]
            $0[>] {
                $0["Free", +] = free?[/3]
                $0["Enslaved", +] = enslaved?[/3]
            }
        }
    }
    func tooltip(occupation: PopOccupation) -> Tooltip? {
        guard
        let row: Delta<PopulationStats.Row> = self.Δ.stats.pops.occupation[occupation] else {
            return nil
        }

        let total: Delta<Int64> = self.Δ.stats.pops.free.total
        guard
        let share: Delta<Double> = row.count.percentage(of: total) else {
            return nil
        }

        return .instructions(style: .borderless) {
            $0[occupation.plural, +] = share[%3]
            $0[>] {
                $0["Unemployment rate", -] = row.unemployed.percentage(of: row.count)?[%3]
            }
        }
    }
}
extension TileSnapshot {
    func tooltipGDP(
        context: GameUI.CacheContext
    ) -> Tooltip {
        .instructions {
            $0["GDP", +] = self.Δ.stats.economy.gdp[/3]

            let average: Delta<Mean<EconomicStats>> = self.Δ.stats.μFree
            $0[>] {
                $0["GDP per capita", +] = average.gdp[/3..2]
            }

            /// average across sexes
            let incomeUpper: Delta<EconomicLedger.LinearMetrics> = self.Δ.stats.economy.incomeUpper.all
            let incomeLower: Delta<EconomicLedger.LinearMetrics> = self.Δ.stats.economy.incomeLower.all
            let incomeAll: Delta<EconomicLedger.LinearMetrics> = incomeUpper + incomeLower
            $0["Income per capita", +] = incomeAll.μ.incomeTotal[/3..2]
            $0[>] {
                $0["Clerks", +] = incomeUpper.μ.incomeTotal[/3..2]
                $0["Workers", +] = incomeLower.μ.incomeTotal[/3..2]
            }
        }
    }
    func tooltipIndustry(
        _ id: EconomicLedger.Industry,
        context: GameUI.CacheContext
    ) -> Tooltip? {
        guard
        let country: DiplomaticAuthority = self.country,
        let value: Int64 = context.ledger.valueAdded[self.id / id] else {
            return nil
        }

        let total: (world: Int64, local: Int64, localExcluded: Int64) = self.aggregate(
            where: id,
            among: context.ledger.valueAdded,
            worldContribution: { $0 },
            localContribution: { $0 }
        )

        let industryName: String?
        switch id {
        case .building(let type):
            industryName = context.rules.buildings[type]?.title
        case .factory(let type):
            industryName = context.rules.factories[type]?.title
        case .artisan(let type):
            industryName = context.rules.resources[type].title
        case .slavery(let type):
            industryName = context.rules.pops.cultures[type]?.name
        }

        return .instructions(style: .borderless) {
            $0[industryName ?? "?"] = (
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
        _ resource: Resource,
        context: GameUI.CacheContext,
    ) -> Tooltip? {
        guard
        let country: DiplomaticAuthority = self.country,
        let traded: TradeVolume = context.ledger.resource[self.id / resource] else {
            return nil
        }

        let total: (world: Int64, local: Int64, localExcluded: Int64) = self.aggregate(
            where: resource,
            among: context.ledger.resource,
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
        _ resource: Resource,
        context: GameUI.CacheContext,
    ) -> Tooltip? {
        guard
        let country: DiplomaticAuthority = self.country,
        let traded: TradeVolume = context.ledger.resource[self.id / resource] else {
            return nil
        }

        let total: (world: Int64, local: Int64, localExcluded: Int64) = self.aggregate(
            where: resource,
            among: context.ledger.resource,
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
