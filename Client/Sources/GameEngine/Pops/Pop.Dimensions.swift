import GameEconomy

extension Pop {
    struct Dimensions: LegalEntityMetrics {
        var size: Int64
        var mil: Double
        var con: Double
        var fl: Double
        var fe: Double
        var fx: Double
        var px: Double
        /// Investor confidence, a number between 0 and 1.
        var pa: Double
    }
}
extension Pop.Dimensions {
    init() {
        self.init(size: 0, mil: 0, con: 0, fl: 0, fe: 0, fx: 0, px: 1, pa: 0.5)
    }
}

#if TESTABLE
extension Pop.Dimensions: Equatable, Hashable {}
#endif
