import Fraction
import JavaScriptInterop

extension EconomicLedger {
    struct LaborMetrics {
        var count: Int64
        var employed: Int64
    }
}
extension EconomicLedger.LaborMetrics: AdditiveArithmetic {
    static var zero: Self { .init(count: 0, employed: 0) }

    static func + (a: Self, b: Self) -> Self {
        .init(count: a.count + b.count, employed: a.employed + b.employed)
    }
    static func - (a: Self, b: Self) -> Self {
        .init(count: a.count - b.count, employed: a.employed - b.employed)
    }
}
extension EconomicLedger.LaborMetrics {
    var unemployed: Int64 { self.count - self.employed }
    var employment: Double? {
        self.count > 0 ? Double.init(self.employed) / Double.init(self.count) : nil
    }

    /// Returns the scaling factor for mine expansion probability, assuming this row
    /// represents ``PopType/Miner`` pops.
    var mineExpansionFactor: Fraction? {
        self.count > 0 ? self.unemployed %/ (30 * self.count) : nil
    }
}
extension EconomicLedger.LaborMetrics {
    enum ObjectKey: JSString, Sendable {
        case count = "N"
        case employed = "e"
    }
}
extension EconomicLedger.LaborMetrics: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.count] = self.count
        js[.employed] = self.employed
    }
}
extension EconomicLedger.LaborMetrics: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            count: try js[.count].decode(),
            employed: try js[.employed].decode()
        )
    }
}
#if TESTABLE
extension EconomicLedger.LaborMetrics: Equatable {}
#endif
