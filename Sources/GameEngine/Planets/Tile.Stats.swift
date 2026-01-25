import GameIDs
import JavaScriptInterop

extension Tile {
    struct Stats {
        var economy: EconomicStats
        var pops: PopulationStats
    }
}
extension Tile.Stats {
    init() {
        self.init(economy: .zero, pops: .init())
    }
}
extension Tile.Stats {
    var μFree: Mean<EconomicStats> {
        .init(fields: self.economy, weight: Double.init(self.pops.free.total))
    }
}
extension Tile.Stats {
    mutating func startIndexCount() {
        self.economy.startIndexCount()
        self.pops.startIndexCount()
    }
}
extension Tile.Stats {
    enum ObjectKey: JSString, Sendable {
        case pops_occupation = "pO"
        case pops_employed = "pW"
        case pops_enslaved = "pE"
        case pops_free = "pF"
        case economy_gdp = "eG"
        case economy_incomeUpper = "eU"
        case economy_incomeLower = "eL"
    }
}
extension Tile.Stats: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.pops_occupation] = self.pops.occupation.sorted
        js[.pops_employed] = self.pops.employed
        js[.pops_enslaved] = self.pops.enslaved
        js[.pops_free] = self.pops.free
        js[.economy_gdp] = self.economy.gdp
        js[.economy_incomeUpper] = self.economy.incomeUpper
        js[.economy_incomeLower] = self.economy.incomeLower
    }
}
extension Tile.Stats: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            economy: .init(
                gdp: try js[.economy_gdp].decode(),
                incomeUpper: try js[.economy_incomeUpper].decode(),
                incomeLower: try js[.economy_incomeLower].decode(),
            ),
            pops: .init(
                occupation: try js[.pops_occupation].decode(
                    with: \[PopOccupation: PopulationStats.Row].Sorted.dictionary
                ),
                employed: try js[.pops_employed].decode(),
                enslaved: try js[.pops_enslaved].decode(),
                free: try js[.pops_free].decode(),
            ),
        )
    }
}
#if TESTABLE
extension Tile.Stats: Equatable {}
#endif
