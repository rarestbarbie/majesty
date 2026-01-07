struct RegionalStats {
    var pops: PopulationStats
    var gdp: Double

    init() {
        self.pops = .init()
        self.gdp = 0
    }
}
extension RegionalStats {
    mutating func startIndexCount() {
        self.pops.startIndexCount()
        self.gdp = 0
    }
}
