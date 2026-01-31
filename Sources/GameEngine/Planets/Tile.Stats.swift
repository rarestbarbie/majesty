import GameIDs
import GameUI
import JavaScriptInterop

extension Tile {
    struct Stats {
        var gdp: Int64
        var gnp: Double
        var incomeElite: Sex.Stratified<EconomicLedger.IncomeMetrics>
        var incomeUpper: Sex.Stratified<EconomicLedger.IncomeMetrics>
        var incomeLower: Sex.Stratified<EconomicLedger.IncomeMetrics>
        var slaves: EconomicLedger.SocialMetrics
        var voters: EconomicLedger.SocialMetrics
    }
}
extension Tile.Stats {
    static var zero: Self {
        self.init(
            gdp: 0,
            gnp: 0,
            incomeElite: .zero,
            incomeUpper: .zero,
            incomeLower: .zero,
            slaves: .zero,
            voters: .zero,
        )
    }
}
extension Tile.Stats {
    func w0(_ type: PopType) -> Double {
        switch type.stratum {
        case .Worker: self.incomeLower[type.gender.sex].μ.incomeTotal
        case .Clerk: self.incomeUpper[type.gender.sex].μ.incomeTotal
        default: 0
        }
    }

    var _μFree: Mean<Self> {
        .init(fields: self, weight: Double.init(self.voters.count))
    }
}
extension Tile.Stats {
    mutating func startIndexCount() {
        self = .zero
    }
    mutating func afterIndexCount() {
        // TODO: implement actual sex-dependent weighting
        let votersElite: Sex.Stratified<EconomicLedger.SocialMetrics> = self.incomeElite.map(\.social)
        let votersUpper: Sex.Stratified<EconomicLedger.SocialMetrics> = self.incomeUpper.map(\.social)
        let votersLower: Sex.Stratified<EconomicLedger.SocialMetrics> = self.incomeLower.map(\.social)

        let votersBySex: Sex.Stratified<EconomicLedger.SocialMetrics> = votersElite
            + votersUpper
            + votersLower

        self.voters = votersBySex.all
    }
}
extension Tile.Stats {
    enum ObjectKey: JSString, Sendable {
        case gdp = "eG"
        case gnp = "eN"
        case incomeElite = "eE"
        case incomeUpper = "eU"
        case incomeLower = "eL"
        case slaves = "eS"
        case voters = "v"
    }
}
extension Tile.Stats: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.gdp] = self.gdp
        js[.gnp] = self.gnp
        js[.incomeElite] = self.incomeElite
        js[.incomeUpper] = self.incomeUpper
        js[.incomeLower] = self.incomeLower
        js[.slaves] = self.slaves
        js[.voters] = self.voters
    }
}
extension Tile.Stats: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            gdp: try js[.gdp].decode(),
            gnp: try js[.gnp].decode(),
            incomeElite: try js[.incomeElite].decode(),
            incomeUpper: try js[.incomeUpper].decode(),
            incomeLower: try js[.incomeLower].decode(),
            slaves: try js[.slaves].decode(),
            voters: try js[.voters].decode(),
        )
    }
}
#if TESTABLE
extension Tile.Stats: Equatable {}
#endif
