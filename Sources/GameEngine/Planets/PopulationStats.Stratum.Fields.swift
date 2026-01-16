extension PopulationStats.Stratum {
    struct Fields {
        var mil: Double
        var con: Double
    }
}
extension PopulationStats.Stratum.Fields {
    static var zero: Self {
        .init(
            mil: 0,
            con: 0
        )
    }
}
#if TESTABLE
extension PopulationStats.Stratum.Fields: Equatable, Hashable {}
#endif
