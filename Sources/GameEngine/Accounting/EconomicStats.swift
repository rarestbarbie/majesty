struct EconomicStats {
    var gdp: Int64
}
extension EconomicStats {
    static var zero: Self { .init(gdp: 0) }
}
extension EconomicStats {
    mutating func startIndexCount() {
        self.gdp = 0
    }
}
#if TESTABLE
extension EconomicStats: Equatable {}
#endif
