import JavaScriptInterop

extension EconomicLedger {
    struct LinearMetrics {
        private(set) var count: Int64

        private(set) var incomeSubsidies: Int64
        private(set) var incomeFromEmployment: Int64
        private(set) var incomeSelfEmployment: Int64

        private(set) var mil: Double
        private(set) var con: Double
    }
}
extension EconomicLedger.LinearMetrics {
    var incomeTotal: Int64 {
        self.incomeSubsidies + self.incomeFromEmployment + self.incomeSelfEmployment
    }
}
extension EconomicLedger.LinearMetrics {
    mutating func count(
        _ pop: Pop,
        incomeSubsidies: Int64,
        incomeFromEmployment: Int64,
        incomeSelfEmployment: Int64
    ) {
        self.count += pop.z.total

        self.incomeSubsidies += incomeSubsidies
        self.incomeFromEmployment += incomeFromEmployment
        self.incomeSelfEmployment += incomeSelfEmployment

        self.mil += pop.z.mil
        self.con += pop.z.con
    }
}
extension EconomicLedger.LinearMetrics: MeanAggregatable {
    var weighted: Self { self }
    var weight: Double { Double.init(self.count) }
}
extension EconomicLedger.LinearMetrics: AdditiveArithmetic {
    static var zero: Self {
        .init(
            count: 0,
            incomeSubsidies: 0,
            incomeFromEmployment: 0,
            incomeSelfEmployment: 0,
            mil: 0,
            con: 0,
        )
    }

    static func + (self: consuming Self, other: Self) -> Self {
        self += other
        return self
    }
    static func - (self: consuming Self, other: Self) -> Self {
        self -= other
        return self
    }
}
extension EconomicLedger.LinearMetrics {
    static func += (self: inout Self, other: Self) {
        self.count += other.count

        self.incomeSubsidies += other.incomeSubsidies
        self.incomeFromEmployment += other.incomeFromEmployment
        self.incomeSelfEmployment += other.incomeSelfEmployment
        self.mil += other.mil
        self.con += other.con
    }

    static func -= (self: inout Self, other: Self) {
        self.count -= other.count

        self.incomeSubsidies -= other.incomeSubsidies
        self.incomeFromEmployment -= other.incomeFromEmployment
        self.incomeSelfEmployment -= other.incomeSelfEmployment
        self.mil -= other.mil
        self.con -= other.con
    }
}
extension EconomicLedger.LinearMetrics: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case count = "c"
        case incomeSubsidies = "s"
        case incomeFromEmployment = "i"
        case incomeSelfEmployment = "r"
        case mil = "m"
        case con = "n"
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.count] = self.count
        js[.incomeSubsidies] = self.incomeSubsidies
        js[.incomeFromEmployment] = self.incomeFromEmployment
        js[.incomeSelfEmployment] = self.incomeSelfEmployment
        js[.mil] = self.mil
        js[.con] = self.con
    }
}
extension EconomicLedger.LinearMetrics: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            count: try js[.count].decode(),
            incomeSubsidies: try js[.incomeSubsidies].decode(),
            incomeFromEmployment: try js[.incomeFromEmployment].decode(),
            incomeSelfEmployment: try js[.incomeSelfEmployment].decode(),
            mil: try js[.mil].decode(),
            con: try js[.con].decode()
        )
    }
}
#if TESTABLE
extension EconomicLedger.LinearMetrics: Equatable {}
#endif
