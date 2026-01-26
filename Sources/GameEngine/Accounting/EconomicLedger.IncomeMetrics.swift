import JavaScriptInterop

extension EconomicLedger {
    struct IncomeMetrics {
        private(set) var count: Int64
        private(set) var mil: Double
        private(set) var con: Double

        private(set) var incomeSubsidies: Int64
        private(set) var incomeFromEmployment: Int64
        private(set) var incomeSelfEmployment: Int64
    }
}
extension EconomicLedger.IncomeMetrics {
    var incomeTotal: Int64 {
        self.incomeSubsidies + self.incomeFromEmployment + self.incomeSelfEmployment
    }

    var social: EconomicLedger.SocialMetrics {
        .init(
            count: self.count,
            mil: self.mil,
            con: self.con
        )
    }
}
extension EconomicLedger.IncomeMetrics {
    mutating func count(
        free pop: Pop,
        incomeSubsidies: Int64,
        incomeFromEmployment: Int64,
        incomeSelfEmployment: Int64
    ) {
        self.count += pop.z.total

        let weight: Double = Double.init(pop.z.total)
        self.mil += weight * pop.z.mil
        self.con += weight * pop.z.con

        self.incomeSubsidies += incomeSubsidies
        self.incomeFromEmployment += incomeFromEmployment
        self.incomeSelfEmployment += incomeSelfEmployment
    }
}
extension EconomicLedger.IncomeMetrics: MeanAggregatable {
    var weighted: Self { self }
    var weight: Double { Double.init(self.count) }
}
extension EconomicLedger.IncomeMetrics: AdditiveArithmetic {
    static var zero: Self {
        .init(
            count: 0,
            mil: 0,
            con: 0,
            incomeSubsidies: 0,
            incomeFromEmployment: 0,
            incomeSelfEmployment: 0,
        )
    }

    static func + (a: Self, b: Self) -> Self {
        self.init(
            count: a.count + b.count,
            mil: a.mil + b.mil,
            con: a.con + b.con,
            incomeSubsidies: a.incomeSubsidies + b.incomeSubsidies,
            incomeFromEmployment: a.incomeFromEmployment + b.incomeFromEmployment,
            incomeSelfEmployment: a.incomeSelfEmployment + b.incomeSelfEmployment,
        )
    }
    static func - (a: Self, b: Self) -> Self {
        self.init(
            count: a.count - b.count,
            mil: a.mil - b.mil,
            con: a.con - b.con,
            incomeSubsidies: a.incomeSubsidies - b.incomeSubsidies,
            incomeFromEmployment: a.incomeFromEmployment - b.incomeFromEmployment,
            incomeSelfEmployment: a.incomeSelfEmployment - b.incomeSelfEmployment,
        )
    }
}
extension EconomicLedger.IncomeMetrics: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case count = "N"
        case mil = "m"
        case con = "c"
        case incomeSubsidies = "s"
        case incomeFromEmployment = "i"
        case incomeSelfEmployment = "r"
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.count] = self.count
        js[.mil] = self.mil
        js[.con] = self.con
        js[.incomeSubsidies] = self.incomeSubsidies
        js[.incomeFromEmployment] = self.incomeFromEmployment
        js[.incomeSelfEmployment] = self.incomeSelfEmployment
    }
}
extension EconomicLedger.IncomeMetrics: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            count: try js[.count].decode(),
            mil: try js[.mil].decode(),
            con: try js[.con].decode(),
            incomeSubsidies: try js[.incomeSubsidies].decode(),
            incomeFromEmployment: try js[.incomeFromEmployment].decode(),
            incomeSelfEmployment: try js[.incomeSelfEmployment].decode(),
        )
    }
}
#if TESTABLE
extension EconomicLedger.IncomeMetrics: Equatable {}
#endif
