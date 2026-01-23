import GameIDs

struct PopulationStats {
    var occupation: [PopOccupation: Row]
    var employed: Int64
    var enslaved: Stratum
    var free: Stratum
}
extension PopulationStats {
    init() {
        self.init(occupation: [:], employed: 0, enslaved: .init(), free: .init())
    }
}
extension PopulationStats {
    var total: Int64 { self.free.total + self.enslaved.total }
}
extension PopulationStats {
    mutating func startIndexCount() {
        self.occupation.removeAll(keepingCapacity: true)
        self.employed = 0
        self.enslaved.startIndexCount()
        self.free.startIndexCount()
    }

    mutating func addResidentCount(_ pop: Pop, _ stats: Pop.Stats) {
        {
            $0.count += pop.z.total
            $0.employed += stats.employedBeforeEgress
        } (&self.occupation[pop.occupation, default: .zero])

        if pop.type.stratum <= .Ward {
            self.enslaved.addResidentCount(pop)
        } else {
            self.employed += stats.employedBeforeEgress
            self.free.addResidentCount(pop)
        }
    }
}
#if TESTABLE
extension PopulationStats: Equatable {}
#endif
