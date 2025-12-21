import GameIDs

final class RegionalAuthority: Identifiable {
    let id: Address
    private(set) var name: String
    private(set) var governedBy: CountryID
    private(set) var occupiedBy: CountryID
    private(set) var suzerain: CountryID?
    private var country: CountryProperties
    private(set) var pops: PopulationStats

    init(
        id: Address,
        name: String,
        governedBy: CountryID,
        occupiedBy: CountryID,
        suzerain: CountryID?,
        country: CountryProperties,
    ) {
        self.id = id
        self.name = name
        self.governedBy = governedBy
        self.occupiedBy = occupiedBy
        self.suzerain = suzerain
        self.country = country
        self.pops = .init()
    }
}
extension RegionalAuthority {
    var bloc: CountryID { self.suzerain ?? self.governedBy }
    var properties: RegionalProperties {
        .init(id: self.id, name: self.name, pops: self.pops, country: self.country)
    }
}
extension RegionalAuthority {
    func update(
        name: String,
        governedBy: CountryID,
        occupiedBy: CountryID,
        suzerain: CountryID?,
        country: CountryProperties,
    ) {
        self.name = name
        self.governedBy = governedBy
        self.occupiedBy = occupiedBy
        self.suzerain = suzerain
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
