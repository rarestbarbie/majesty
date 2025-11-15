final class RegionalProperties {
    var governedBy: CountryProperties
    var occupiedBy: CountryProperties
    private(set) var pops: PopulationStats

    init(
        governedBy: CountryProperties,
        occupiedBy: CountryProperties
    ) {
        self.governedBy = governedBy
        self.occupiedBy = occupiedBy
        self.pops = .init()
    }
}
extension RegionalProperties {
    var minwage: Int64 {
        self.governedBy.minwage
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
