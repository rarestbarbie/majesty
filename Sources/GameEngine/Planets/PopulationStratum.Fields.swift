extension PopulationStratum {
    struct Fields {
        var mil: Double
        var con: Double
    }
}
extension PopulationStratum.Fields {
    static var zero: Self {
        .init(
            mil: 0,
            con: 0
        )
    }
}
