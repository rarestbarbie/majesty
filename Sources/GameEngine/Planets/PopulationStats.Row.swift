import Fraction
import JavaScriptInterop

extension PopulationStats {
    struct Row {
        var count: Int64
        var employed: Int64
    }
}
extension PopulationStats.Row: AdditiveArithmetic {
    static var zero: Self { .init(count: 0, employed: 0) }

    static func + (a: Self, b: Self) -> Self {
        .init(count: a.count + b.count, employed: a.employed + b.employed)
    }
    static func - (a: Self, b: Self) -> Self {
        .init(count: a.count - b.count, employed: a.employed - b.employed)
    }
}
extension PopulationStats.Row {
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
extension PopulationStats.Row {
    enum ObjectKey: JSString, Sendable {
        case count = "n"
        case employed = "e"
    }
}
extension PopulationStats.Row: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<PopulationStats.Row.ObjectKey>) {
        js[.count] = self.count
        js[.employed] = self.employed
    }
}
extension PopulationStats.Row: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<PopulationStats.Row.ObjectKey>) throws {
        self.init(
            count: try js[.count].decode(),
            employed: try js[.employed].decode()
        )
    }
}
#if TESTABLE
extension PopulationStats.Row: Equatable {}
#endif
