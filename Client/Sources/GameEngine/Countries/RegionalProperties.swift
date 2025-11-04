final class RegionalProperties {
    private(set) var governedBy: CountryProperties?
    private(set) var occupiedBy: CountryProperties?
    private(set) var pops: PopulationStats

    init() {
        self.governedBy = nil
        self.occupiedBy = nil
        self.pops = .init()
    }
}
extension RegionalProperties {
    var minwage: Int64 {
        self.governedBy?.minwage ?? 1
    }
}
extension RegionalProperties {
    func assign(
        governedBy: CountryProperties?,
        occupiedBy: CountryProperties?
    ) {
        self.governedBy = governedBy
        self.occupiedBy = occupiedBy
    }

    func startIndexCount() {
        self.pops.startIndexCount()
    }

    func addResidentCount(_ pop: Pop) {
        self.pops.addResidentCount(pop)
    }
}
