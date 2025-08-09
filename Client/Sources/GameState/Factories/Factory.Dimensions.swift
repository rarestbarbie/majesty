extension Factory {
    struct Dimensions {
        var vi: Int64
        var vv: Int64

        /// Official wage paid to non-union workers.
        var wn: Int64
        /// Official wage paid to union workers.
        var wu: Int64

        /// Official wage paid to non-union clerks.
        var cn: Int64
        /// Official wage paid to union clerks.
        var cu: Int64

        /// Actual, average wage paid to non-union workers.
        var wna: Double
        /// Actual, average wage paid to union workers.
        var wua: Double
        /// Actual, average salary paid to clerks. (No distinction between union and non-union.)
        var caa: Double

        /// Worker raise probability, set if the factory couldn’t hire any workers.
        ///
        /// The probability is 1 when this value equals ``FactoryContext.pr``.
        var wf: Int?
        /// Clerk raise probability, set if the factory couldn’t hire any clerks.
        var cf: Int?

        /// Input efficiency.
        var ei: Double
        /// Output efficiency.
        var eo: Double

        var fi: Double
    }
}

#if TESTABLE
extension Factory.Dimensions: Equatable, Hashable {}
#endif
