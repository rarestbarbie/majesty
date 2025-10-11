import GameEconomy

extension Factory {
    struct Dimensions: LegalEntityMetrics {
        var vi: Int64
        var vx: Int64

        /// Worker raise probability, set if the factory couldn’t hire any workers.
        ///
        /// The probability is 1 when this value equals ``FactoryContext.pr``.
        var wf: Int?
        /// Official wage paid to workers.
        var wn: Int64

        /// Clerk raise probability, set if the factory couldn’t hire any clerks.
        var cf: Int?
        /// Official wage paid to clerks.
        var cn: Int64

        /// Input efficiency.
        var ei: Double
        /// Output efficiency.
        var eo: Double

        var fi: Double

        /// Share price.
        var px: Double
        /// Investor confidence, a number between 0 and 1.
        var pa: Double
    }
}
extension Factory.Dimensions {
    init() {
        self.init(
            vi: 0,
            vx: 0,
            wf: nil,
            wn: 1,
            cf: nil,
            cn: 1,
            ei: 1,
            eo: 1,
            fi: 0,
            px: 1,
            pa: 1
        )
    }
}

#if TESTABLE
extension Factory.Dimensions: Equatable, Hashable {}
#endif
