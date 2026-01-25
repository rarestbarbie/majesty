import GameIDs

struct EconomicStats {
    var gdp: Int64
    var incomeUpper: Sex.Stratified<EconomicLedger.LinearMetrics>
    var incomeLower: Sex.Stratified<EconomicLedger.LinearMetrics>
}
extension EconomicStats {
    static var zero: Self {
        .init(
            gdp: 0,
            incomeUpper: .zero,
            incomeLower: .zero
        )
    }
}
extension EconomicStats {
    mutating func startIndexCount() {
        self = .zero
    }
}
#if TESTABLE
extension EconomicStats: Equatable {}
#endif
