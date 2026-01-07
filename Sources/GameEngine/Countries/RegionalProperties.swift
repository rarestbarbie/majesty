import GameIDs

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
