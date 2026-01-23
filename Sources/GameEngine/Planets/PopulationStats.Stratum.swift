import GameIDs
import JavaScriptInterop

extension PopulationStats {
    @dynamicMemberLookup struct Stratum {
        var total: Int64
        var cultures: [CultureID: Int64]
        var weighted: Fields
    }
}
extension PopulationStats.Stratum {
    init() {
        self.init(total: 0, cultures: [:], weighted: .zero)
    }
}
extension PopulationStats.Stratum {
    subscript<Float>(dynamicMember keyPath: KeyPath<Fields, Float>) -> (
        average: Float,
        of: Float
    ) where Float: BinaryFloatingPoint {
        let population: Float = .init(self.total)
        if  population <= 0 {
            return (0, 0)
        } else {
            return (self.weighted[keyPath: keyPath] / population, population)
        }
    }
}
extension PopulationStats.Stratum {
    mutating func startIndexCount() {
        // use the previous day’s counts to allocate capacity
        let cultures: Int = self.cultures.count

        self.total = 0

        self.cultures = [:]
        self.cultures.reserveCapacity(cultures)

        self.weighted = .zero
    }

    mutating func addResidentCount(_ pop: Pop) {
        let weight: Double = .init(pop.z.total)
        self.total += pop.z.total
        self.cultures[pop.race, default: 0] += pop.z.total
        self.weighted.mil += pop.z.mil * weight
        self.weighted.con += pop.z.con * weight
    }
}
extension PopulationStats.Stratum {
    enum ObjectKey: JSString, Sendable {
        case total = "t"
        case cultures = "c"
        case weighted_mil = "wM"
        case weighted_con = "wC"
    }
}
extension PopulationStats.Stratum: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.total] = self.total
        js[.cultures] = self.cultures.sorted
        js[.weighted_mil] = self.weighted.mil
        js[.weighted_con] = self.weighted.con
    }
}
extension PopulationStats.Stratum: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<PopulationStats.Stratum.ObjectKey>) throws {
        self.init(
            total: try js[.total].decode(),
            cultures: try js[.cultures].decode(with: \[CultureID: Int64].Sorted.dictionary),
            weighted: .init(
                mil: try js[.weighted_mil].decode(),
                con: try js[.weighted_con].decode()
            )
        )
    }
}
#if TESTABLE
extension PopulationStats.Stratum: Equatable {}
#endif
