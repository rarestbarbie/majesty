import JavaScriptInterop

extension EconomicLedger {
    struct SocialMetrics {
        private(set) var count: Int64
        private(set) var mil: Double
        private(set) var con: Double
    }
}
extension EconomicLedger.SocialMetrics {
    mutating func count(
        slave pop: Pop
    ) {
        self.count += pop.z.total
        self.mil += pop.z.mil
        self.con += pop.z.con
    }
}
extension EconomicLedger.SocialMetrics: MeanAggregatable {
    var weighted: Self { self }
    var weight: Double { Double.init(self.count) }
}
extension EconomicLedger.SocialMetrics: AdditiveArithmetic {
    static var zero: Self {
        .init(
            count: 0,
            mil: 0,
            con: 0,
        )
    }

    static func + (a: Self, b: Self) -> Self {
        self.init(
            count: a.count + b.count,
            mil: a.mil + b.mil,
            con: a.con + b.con,
        )
    }
    static func - (a: Self, b: Self) -> Self {
        self.init(
            count: a.count - b.count,
            mil: a.mil - b.mil,
            con: a.con - b.con,
        )
    }
}
extension EconomicLedger.SocialMetrics: JavaScriptEncodable {
    enum ObjectKey: JSString, Sendable {
        case count = "N"
        case mil = "m"
        case con = "c"
    }

    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.count] = self.count
        js[.mil] = self.mil
        js[.con] = self.con
    }
}
extension EconomicLedger.SocialMetrics: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            count: try js[.count].decode(),
            mil: try js[.mil].decode(),
            con: try js[.con].decode()
        )
    }
}
#if TESTABLE
extension EconomicLedger.SocialMetrics: Equatable {}
#endif
