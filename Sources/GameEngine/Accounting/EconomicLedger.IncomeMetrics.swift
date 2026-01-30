import JavaScriptInterop

extension EconomicLedger {
    struct IncomeMetrics: SocialMetricsAggregatable {
        private(set) var count: Int64
        private(set) var mil: Double
        private(set) var con: Double

        private(set) var incomeLessTransfers: Int64
        private(set) var incomeFromTransfers: Int64
    }
}
extension EconomicLedger.IncomeMetrics {
    var incomeTotal: Int64 {
        self.incomeLessTransfers + self.incomeFromTransfers
    }
}
extension EconomicLedger.IncomeMetrics {
    mutating func count(
        free pop: Pop,
        incomeLessTransfers: Int64,
        incomeFromTransfers: Int64
    ) {
        self.count += pop.z.total

        let weight: Double = Double.init(pop.z.total)
        self.mil += weight * pop.z.mil
        self.con += weight * pop.z.con

        self.incomeLessTransfers += incomeLessTransfers
        self.incomeFromTransfers += incomeFromTransfers
    }
}
extension EconomicLedger.IncomeMetrics: AdditiveArithmetic {
    static var zero: Self {
        .init(
            count: 0,
            mil: 0,
            con: 0,
            incomeLessTransfers: 0,
            incomeFromTransfers: 0,
        )
    }

    static func + (a: Self, b: Self) -> Self {
        self.init(
            count: a.count + b.count,
            mil: a.mil + b.mil,
            con: a.con + b.con,
            incomeLessTransfers: a.incomeLessTransfers + b.incomeLessTransfers,
            incomeFromTransfers: a.incomeFromTransfers + b.incomeFromTransfers,
        )
    }
    static func - (a: Self, b: Self) -> Self {
        self.init(
            count: a.count - b.count,
            mil: a.mil - b.mil,
            con: a.con - b.con,
            incomeLessTransfers: a.incomeLessTransfers - b.incomeLessTransfers,
            incomeFromTransfers: a.incomeFromTransfers - b.incomeFromTransfers,
        )
    }
}
extension EconomicLedger.IncomeMetrics: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case count = "N"
        case mil = "m"
        case con = "c"
        case incomeLessTransfers = "i"
        case incomeFromTransfers = "j"
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.count] = self.count
        js[.mil] = self.mil
        js[.con] = self.con
        js[.incomeLessTransfers] = self.incomeLessTransfers != 0
            ? self.incomeLessTransfers
            : nil
        js[.incomeFromTransfers] = self.incomeFromTransfers != 0
            ? self.incomeFromTransfers
            : nil
    }
}
extension EconomicLedger.IncomeMetrics: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            count: try js[.count].decode(),
            mil: try js[.mil].decode(),
            con: try js[.con].decode(),
            incomeLessTransfers: try js[.incomeLessTransfers]?.decode() ?? 0,
            incomeFromTransfers: try js[.incomeFromTransfers]?.decode() ?? 0
        )
    }
}
#if TESTABLE
extension EconomicLedger.IncomeMetrics: Equatable {}
#endif
