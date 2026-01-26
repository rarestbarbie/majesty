import GameIDs

final class RegionalProperties: Sendable {
    let id: Address
    let name: String
    let country: DiplomaticAuthority
    let stats: Tile.Stats
    private let state: Tile.Dimensions

    init(
        id: Address,
        name: String,
        country: DiplomaticAuthority,
        stats: Tile.Stats,
        state: Tile.Dimensions
    ) {
        self.id = id
        self.name = name
        self.country = country
        self.stats = stats
        self.state = state
    }
}
extension RegionalProperties {
    var occupiedBy: CountryID { self.country.occupiedBy }
    var governedBy: CountryID { self.country.governedBy }

    var modifiers: CountryModifiers { self.country.modifiers }
    var currency: Currency { self.country.currency }
    var minwage: Int64 { self.country.minwage }
}
