import GameIDs

final class RegionalAuthority: Identifiable {
    let id: Address
    private(set) var governedBy: CountryID
    private(set) var occupiedBy: CountryID
    private var country: CountryProperties
    private(set) var pops: PopulationStats

    init(
        id: Address,
        governedBy: CountryID,
        occupiedBy: CountryID,
        country: CountryProperties,
    ) {
        self.id = id
        self.governedBy = governedBy
        self.occupiedBy = occupiedBy
        self.country = country
        self.pops = .init()
    }
}
extension RegionalAuthority {
    var properties: RegionalProperties {
        .init(id: self.id, pops: self.pops, country: self.country)
    }
}
extension RegionalAuthority {
    func update(
        governedBy: CountryID,
        occupiedBy: CountryID,
        country: CountryProperties,
    ) {
        self.governedBy = governedBy
        self.occupiedBy = occupiedBy
        self.country = country
    }
}
extension RegionalAuthority {
    func startIndexCount() {
        self.pops.startIndexCount()
    }

    func addResidentCount(_ pop: Pop, _ stats: Pop.Stats) {
        self.pops.addResidentCount(pop, stats)
    }
}
