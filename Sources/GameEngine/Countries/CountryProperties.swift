import GameEconomy
import GameIDs
import GameRules
import GameState

struct CountryProperties {
    let modifiers: CountryModifiers
    let minwage: Int64
    let currency: Currency
    let culturePreferred: Culture
    let culturesAccepted: [Culture]
    let criticalResources: [Resource]
}
extension CountryProperties {
    static func compute(for country: Country, in context: GameContext) throws -> Self {
        guard
        let currency: Currency = context.currencies[country.currency] else {
            fatalError("Country '\(country.name.long)' has no currency!!!")
        }
        return .init(
            modifiers: .compute(for: country, rules: context.rules),
            minwage: country.minwage,
            currency: currency,
            culturePreferred: try context.cultures.state[country.culturePreferred].state,
            culturesAccepted: try country.culturesAccepted.map {
                try context.cultures.state[$0].state
            },
            criticalResources: context.rules.resources.local.compactMap {
                $0.critical ? $0.id : nil
            }
        )
    }
}
