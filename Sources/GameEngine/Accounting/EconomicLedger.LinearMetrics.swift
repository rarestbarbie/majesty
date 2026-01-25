import JavaScriptInterop

extension EconomicLedger {
    struct LinearMetrics {
        private(set) var count: Int64

        private(set) var incomeSubsidies: Int64
        private(set) var incomeFromWork: Int64

        private(set) var mil: Double
        private(set) var con: Double
    }
}
extension EconomicLedger.LinearMetrics {
    var incomeTotal: Int64 {
        self.incomeSubsidies + self.incomeFromWork
    }
}
extension EconomicLedger.LinearMetrics {
    mutating func count(_ account: Bank.Account, of pop: Pop) {
        self.count += pop.z.total

        self.incomeSubsidies += account.s
        self.incomeFromWork += account.r

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
            incomeFromWork: 0,
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
        self.incomeFromWork += other.incomeFromWork
        self.mil += other.mil
        self.con += other.con
    }

    static func -= (self: inout Self, other: Self) {
        self.count -= other.count

        self.incomeSubsidies -= other.incomeSubsidies
        self.incomeFromWork -= other.incomeFromWork
        self.mil -= other.mil
        self.con -= other.con
    }
}
extension EconomicLedger.LinearMetrics: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case count = "c"
        case incomeSubsidies = "s"
        case incomeFromWork = "r"
        case mil = "m"
        case con = "n"
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.count] = self.count
        js[.incomeSubsidies] = self.incomeSubsidies
        js[.incomeFromWork] = self.incomeFromWork
        js[.mil] = self.mil
        js[.con] = self.con
    }
}
extension EconomicLedger.LinearMetrics: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            count: try js[.count].decode(),
            incomeSubsidies: try js[.incomeSubsidies].decode(),
            incomeFromWork: try js[.incomeFromWork].decode(),
            mil: try js[.mil].decode(),
            con: try js[.con].decode()
        )
    }
}
#if TESTABLE
extension EconomicLedger.LinearMetrics: Equatable {}
#endif
