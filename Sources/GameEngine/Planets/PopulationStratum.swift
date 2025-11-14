import GameIDs

@dynamicMemberLookup
struct PopulationStratum {
    var all: [PopID]
    var total: Int64
    var cultures: [String: Int64]
    var weighted: Fields
}
extension PopulationStratum {
    init() {
        self.init(all: [], total: 0, cultures: [:], weighted: .zero)
    }
}
extension PopulationStratum {
    subscript<Float>(dynamicMember keyPath: KeyPath<Fields, Float>) -> (average: Float, of: Float) where Float: BinaryFloatingPoint {
        let population: Float = .init(self.total)
        if  population < 0 {
            return (0, 0)
        } else {
            return (self.weighted[keyPath: keyPath] / population, population)
        }
    }
}
extension PopulationStratum {
    mutating func startIndexCount() {
        self.all.removeAll(keepingCapacity: true)
        self.total = 0
        self.cultures.removeAll(keepingCapacity: true)
        self.weighted = .zero
    }

    mutating func addResidentCount(_ pop: Pop) {
        let weight: Double = .init(pop.z.size)
        self.all.append(pop.id)
        self.total += pop.z.size
        self.cultures[pop.nat, default: 0] += pop.z.size
        self.weighted.mil += pop.z.mil * weight
        self.weighted.con += pop.z.con * weight
    }
}
