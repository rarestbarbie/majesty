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
}
