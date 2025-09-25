import GameEconomy

extension Factory {
    struct Dimensions {
        var vi: Int64
        var vv: Int64

        /// Actual, average wage paid to workers.
        var wa: Double
        /// Worker raise probability, set if the factory couldn’t hire any workers.
        ///
        /// The probability is 1 when this value equals ``FactoryContext.pr``.
        var wf: Int?
        /// Official wage paid to workers.
        var wn: Int64

        /// Actual, average salary paid to clerks.
        var ca: Double
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
    }
}

#if TESTABLE
extension Factory.Dimensions: Equatable, Hashable {}
#endif
