import D
import Fraction
import GameIDs
import GameUI

final class RegionalProperties: Sendable {
    let id: Address
    let name: String
    let pops: PopulationStats
    /// TODO: group with other economic stats
    let _gdp: Double

    let occupiedBy: CountryID
    let governedBy: CountryID
    let suzerain: CountryID?
    private let country: CountryProperties

    init(
        id: Address,
        name: String,
        pops: PopulationStats,
        _gdp: Double,
        occupiedBy: CountryID,
        governedBy: CountryID,
        suzerain: CountryID?,
        country: CountryProperties,
    ) {
        self.id = id
        self.name = name
        self.pops = pops
        self._gdp = _gdp
        self.occupiedBy = occupiedBy
        self.governedBy = governedBy
        self.suzerain = suzerain
        self.country = country
    }
}
extension RegionalProperties {
    var currency: Currency { self.country.currency }
    var minwage: Int64 { self.country.minwage }
    var culturePreferred: Culture { self.country.culturePreferred }
    var culturesAccepted: [Culture] { self.country.culturesAccepted }
    var modifiers: CountryModifiers { self.country.modifiers }
    var criticalResources: [Resource] { self.country.criticalResources }

    var bloc: CountryID { self.suzerain ?? self.governedBy }
}
extension RegionalProperties {
    func tooltip(culture: Culture) -> Tooltip? {
        let free: Int64? = self.pops.free.cultures[culture.id]
        let enslaved: Int64? = self.pops.enslaved.cultures[culture.id]

        let share: Int64
        let total: Int64

        if  let free: Int64 {
            share = free
            total = self.pops.free.total
        } else if
            let enslaved: Int64 {
            share = enslaved
            total = self.pops.enslaved.total
        } else {
            return nil
        }

        if  total == 0 {
            return nil
        }

        return .instructions(style: .borderless) {
            $0[culture.name] = (Double.init(share) / Double.init(total))[%3]
            $0[>] {
                $0["Free"] = free?[/3]
                $0["Enslaved"] = enslaved?[/3]
            }
        }
    }
    func tooltip(occupation: PopOccupation) -> Tooltip? {
        guard
        let share: PopulationStats.Row = self.pops.occupation[occupation],
            share.count > 0 else {
            return nil
        }

        let total: Int64 = self.pops.free.total

        if  total == 0 {
            return nil
        }

        return .instructions(style: .borderless) {
            let n: Double = Double.init(share.count)
            let d: Double = Double.init(total)
            $0[occupation.plural] = (n / d)[%3]
            $0[>] {
                $0["Unemployment rate", (-)] = (Double.init(share.unemployed) / n)[%3]
            }
        }
    }
}
extension RegionalProperties {
    func tooltipEconomyContribution(
        resource: Resource,
        context: GameUI.CacheContext
    ) -> Tooltip? {
        guard
        let (units, value): (Int64, Double) = context.ledger.produced[self.id / resource] else {
            return nil
        }

        let total: (worldwide: Int64, value: Double) = context.ledger.produced.reduce(
            into: (0, 0)
        ) {
            if  $1.key.resource == resource {
                $0.worldwide += $1.value.units
            }
            if  $1.key.location == self.id {
                $0.value += $1.value.value
            }
        }

        let resourceName: String = context.rules.resources[resource].title

        return .instructions(style: .borderless) {
            $0[resourceName] = (
                total.value > 0 ? value / total.value : 0
            )[%2]
            $0[>] {
                $0["Estimated market value (\(self.country.currency.name))", +] = +?value[/3..2]
            }

            let share: Double = .init(units %/ max(total.worldwide, 1))
            $0[>] = """
            Today this region produced \(em: units[/3]) units of \(em: resourceName) \
            comprising \(em: share[%2]) of world production
            """
        }
    }
}
