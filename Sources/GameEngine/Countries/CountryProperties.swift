import Fraction
import GameEconomy
import GameRules
import GameIDs

final class CountryProperties {
    var intrinsic: Country
    private(set) var modifiers: CountryModifiers
    private(set) var localMarkets: LocalMarketModifiers

    init(intrinsic state: Country) {
        self.intrinsic = state
        self.modifiers = .init()
        self.localMarkets = .init()
    }
}
extension CountryProperties: Identifiable {
    var id: CountryID { self.intrinsic.id }
}
extension CountryProperties {
    var currency: Country.Currency { self.intrinsic.currency }
    var minwage: Int64 { self.intrinsic.minwage }
    var culturePreferred: String { self.intrinsic.culturePreferred }
}
extension CountryProperties {
    func update(rules: GameRules) {
        self.modifiers = .init()
        self.modifiers.update(from: self.intrinsic.researched, rules: rules)

        for resource: ResourceMetadata in rules.resources.values where resource.local {
            let min: LocalPriceLevel?

            if let hours: Int64 = resource.hours {
                min = .init(
                    price: LocalPrice.init(self.minwage %/ hours),
                    label: .minimumWage
                )
            } else {
                min = nil
            }

            self.localMarkets.templates[resource.id] = .init(
                storage: resource.storable,
                limit: (min: min, max: nil)
            )
        }
    }
}
