struct RegionalStats {
    private(set) var pops: PopulationStats

    init() {
        self.pops = .init()
    }
}
extension RegionalStats {
    mutating func startIndexCount() {
        self.pops.startIndexCount()
    }

    mutating func addResidentCount(_ pop: Pop, _ stats: Pop.Stats) {
        self.pops.addResidentCount(pop, stats)
    }
}
