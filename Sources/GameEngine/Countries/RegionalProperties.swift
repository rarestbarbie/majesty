import GameIDs

final class RegionalProperties: Identifiable {
    let id: Address
    var governedBy: CountryProperties
    var occupiedBy: CountryProperties
    private(set) var pops: PopulationStats

    init(
        id: Address,
        governedBy: CountryProperties,
        occupiedBy: CountryProperties
    ) {
        self.id = id
        self.governedBy = governedBy
        self.occupiedBy = occupiedBy
        self.pops = .init()
    }
}
extension RegionalProperties {
    func startIndexCount() {
        self.pops.startIndexCount()
    }

    func addResidentCount(_ pop: Pop, _ stats: Pop.Stats) {
        self.pops.addResidentCount(pop, stats)
    }
}
