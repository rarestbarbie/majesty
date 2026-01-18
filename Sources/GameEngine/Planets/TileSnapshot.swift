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
                let free: Delta<Double> = pops.free.mil.average
                $0["Average militancy", -] = free[..2]
                let enslaved: Double = self.z.stats.pops.enslaved.mil.average
                if  self.z.stats.pops.enslaved.total > 0 {
                    $0[>] = """
                    The average militancy of the slave population is \(
                        enslaved[..2],
                        style: enslaved > 1.0 ? .neg : .em
                    )
                    """
                }
            case .AverageConsciousness:
                let free: Delta<Double> = pops.free.con.average
                $0["Average consciousness", -] = free[..2]
                let enslaved: Double = self.z.stats.pops.enslaved.con.average
                if  self.z.stats.pops.enslaved.total > 0 {
                    $0[>] = """
                    The average consciousness of the slave population is \(
                        enslaved[..2],
                        style: enslaved > 1.0 ? .neg : .em
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
    func tooltipEconomyContribution(
        resource: Resource,
        context: GameUI.CacheContext
    ) -> Tooltip? {
        guard
        let country: DiplomaticAuthority = self.country,
        let (units, value): (Int64, Int64) = context.ledger.production[self.id / resource] else {
            return nil
        }

        let total: (worldwide: Int64, value: Int64) = context.ledger.production.reduce(
            into: (0, 0)
        ) {
            if  $1.key.crosstab == resource {
                $0.worldwide += $1.value.units
            }
            if  $1.key.location == self.id {
                $0.value += $1.value.value
            }
        }

        let resourceName: String = context.rules.resources[resource].title

        return .instructions(style: .borderless) {
            $0[resourceName] = (
                total.value > 0 ? Double.init(value %/ total.value) : 0
            )[%2]
            $0[>] {
                $0["Estimated market value (\(country.currency.name))", +] = +?value[/3]
            }

            let share: Double = .init(units %/ max(total.worldwide, 1))
            $0[>] = """
            Today this region produced \(em: units[/3]) units of \(em: resourceName) \
            comprising \(em: share[%2]) of world production
            """
        }
    }
}
