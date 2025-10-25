import GameIDs

struct PopulationStats {
    var type: [PopType: Int64]
    var free: PopulationStratum
    var enslaved: PopulationStratum
}
extension PopulationStats {
    init() {
        self.init(type: [:], free: .init(), enslaved: .init())
    }
}
extension PopulationStats {
    var total: Int64 { self.free.total + self.enslaved.total }
}
extension PopulationStats {
    mutating func startIndexCount() {
        self.type.removeAll(keepingCapacity: true)
        self.free.startIndexCount()
        self.enslaved.startIndexCount()
    }

    mutating func addResidentCount(_ pop: Pop) {
        self.type[pop.type, default: 0] += pop.today.size

        if pop.type.stratum <= .Ward {
            self.enslaved.addResidentCount(pop)
        } else {
            self.free.addResidentCount(pop)
        }
    }
}
