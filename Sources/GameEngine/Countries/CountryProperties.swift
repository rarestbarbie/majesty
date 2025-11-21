import Fraction
import GameEconomy
import GameRules
import GameIDs

final class CountryProperties {
    var intrinsic: Country
    private(set) var modifiers: CountryModifiers
    private(set) var localMarkets: LocalMarketModifiers
    private(set) var criticalResources: [Resource]

    init(intrinsic state: Country) {
        self.intrinsic = state
        self.modifiers = .init()
        self.localMarkets = .init()
        self.criticalResources = []
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
        // right now this never changes, but it might in the future
        self.criticalResources.removeAll(keepingCapacity: true)

        for resource: ResourceMetadata in rules.resources.local {
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
                storage: resource.storable ? 16 : nil,
                limit: (min: min, max: nil)
            )

            if  resource.critical {
                self.criticalResources.append(resource.id)
            }
        }
    }
}
