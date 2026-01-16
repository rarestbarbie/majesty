import GameIDs
import JavaScriptKit
import JavaScriptInterop

extension Tile {
    struct Stats {
        var pops: PopulationStats
        var gdp: Double
    }
}
extension Tile.Stats {
    init() {
        self.init(pops: .init(), gdp: 0)
    }
}
extension Tile.Stats {
    mutating func startIndexCount() {
        self.pops.startIndexCount()
        self.gdp = 0
    }
}
extension Tile.Stats {
    enum ObjectKey: JSString, Sendable {
        case pops_occupation = "pO"
        case pops_employed = "pW"
        case pops_enslaved = "pE"
        case pops_free = "pF"
        case gdp
    }
}
extension Tile.Stats: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.pops_occupation] = self.pops.occupation.sorted
        js[.pops_employed] = self.pops.employed
        js[.pops_enslaved] = self.pops.enslaved
        js[.pops_free] = self.pops.free
        js[.gdp] = self.gdp
    }
}
extension Tile.Stats: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            pops: .init(
                occupation: try js[.pops_occupation].decode(
                    with: \[PopOccupation: PopulationStats.Row].Sorted.dictionary
                ),
                employed: try js[.pops_employed].decode(),
                enslaved: try js[.pops_enslaved].decode(),
                free: try js[.pops_free].decode(),
            ),
            gdp: try js[.gdp].decode()
        )
    }
}
#if TESTABLE
extension Tile.Stats: Equatable, Hashable {}
#endif
