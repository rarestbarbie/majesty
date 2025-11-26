import Fraction

extension PopulationStats {
    struct Row {
        var count: Int64
        var employed: Int64
    }
}
extension PopulationStats.Row {
    static var zero: Self { .init(count: 0, employed: 0) }
}
extension PopulationStats.Row {
    var unemployed: Int64 { self.count - self.employed }
    var employment: Double? {
        self.count > 0 ? Double.init(self.employed) / Double.init(self.count) : nil
    }

    /// Returns the scaling factor for mine expansion probability, assuming this row
    /// represents ``PopType/Miner`` pops.
    var mineExpansionFactor: Fraction? {
        self.count > 0 ? self.unemployed %/ (30 * self.count) : nil
    }
}
