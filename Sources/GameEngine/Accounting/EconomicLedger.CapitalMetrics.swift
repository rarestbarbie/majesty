import JavaScriptInterop

extension EconomicLedger {
    struct CapitalMetrics {
        private(set) var count: Int64
        private(set) var mil: Double
        private(set) var con: Double

        var income: Double
    }
}
extension EconomicLedger.CapitalMetrics {
    var social: EconomicLedger.SocialMetrics {
        .init(
            count: self.count,
            mil: self.mil,
            con: self.con
        )
    }
}
extension EconomicLedger.CapitalMetrics {
    mutating func count(_ pop: Pop, income: Double) {
        self.count += pop.z.total

        let weight: Double = Double.init(pop.z.total)
        self.mil += weight * pop.z.mil
        self.con += weight * pop.z.con

        self.income += income
    }
}
extension EconomicLedger.CapitalMetrics: MeanAggregatable {
    var weighted: Self { self }
    var weight: Double { Double.init(self.count) }
}
extension EconomicLedger.CapitalMetrics: AdditiveArithmetic {
    static var zero: Self {
        .init(
            count: 0,
            mil: 0,
            con: 0,
            income: 0,
        )
    }

    static func + (a: Self, b: Self) -> Self {
        self.init(
            count: a.count + b.count,
            mil: a.mil + b.mil,
            con: a.con + b.con,
            income: a.income + b.income,
        )
    }
    static func - (a: Self, b: Self) -> Self {
        self.init(
            count: a.count - b.count,
            mil: a.mil - b.mil,
            con: a.con - b.con,
            income: a.income - b.income,
        )
    }
}
extension EconomicLedger.CapitalMetrics: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case count = "N"
        case mil = "m"
        case con = "c"
        case income = "i"
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.count] = self.count
        js[.mil] = self.mil
        js[.con] = self.con
        js[.income] = self.income
    }
}
extension EconomicLedger.CapitalMetrics: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            count: try js[.count].decode(),
            mil: try js[.mil].decode(),
            con: try js[.con].decode(),
            income: try js[.income].decode()
        )
    }
}
#if TESTABLE
extension EconomicLedger.CapitalMetrics: Equatable {}
#endif
