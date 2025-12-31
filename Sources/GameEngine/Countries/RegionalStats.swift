struct RegionalStats {
    var pops: PopulationStats

    init() {
        self.pops = .init()
    }
}
extension RegionalStats {
    mutating func startIndexCount() {
        self.pops.startIndexCount()
    }
}
