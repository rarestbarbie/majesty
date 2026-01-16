import GameEconomy
import GameIDs
import GameRules
import GameState

struct DiplomaticAuthority {
    let governedBy: CountryID
    let occupiedBy: CountryID
    let suzerain: CountryID?
    let currency: Currency
    let culturePreferred: Culture
    let culturesAccepted: [Culture]
    let criticalResources: [Resource]
    let modifiers: CountryModifiers
    let minwage: Int64
}
extension DiplomaticAuthority {
    var bloc: CountryID { self.suzerain ?? self.governedBy }

    subscript(region: Address) -> RegionalAuthority {
        .init(id: region, country: self)
    }
}
extension DiplomaticAuthority {
    static func compute(for country: Country, in context: GameContext) throws -> Self {
        guard
        let currency: Currency = context.currencies[country.currency] else {
            fatalError("Country '\(country.name.long)' has no currency!!!")
        }
        return .init(
            governedBy: country.id,
            occupiedBy: country.id,
            suzerain: country.suzerain,
            currency: currency,
            culturePreferred: try context.rules.pops.cultures[defined: country.culturePreferred],
            culturesAccepted: try country.culturesAccepted.map {
                try context.rules.pops.cultures[defined: $0]
            },
            criticalResources: context.rules.resources.local.compactMap {
                $0.critical ? $0.id : nil
            },
            modifiers: .compute(for: country, rules: context.rules),
            minwage: country.minwage,
        )
    }
}
