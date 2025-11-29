import GameIDs

struct RegionalProperties {
    let id: Address
    let pops: PopulationStats
    private let country: CountryProperties

    init(id: Address, pops: PopulationStats, country: CountryProperties) {
        self.id = id
        self.pops = pops
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
}
