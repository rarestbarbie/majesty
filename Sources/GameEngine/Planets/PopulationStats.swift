import GameIDs

struct PopulationStats {
    var occupation: [PopOccupation: Row]
    var free: PopulationStratum
    var enslaved: PopulationStratum
    var employed: Int64
}
extension PopulationStats {
    init() {
        self.init(occupation: [:], free: .init(), enslaved: .init(), employed: 0)
    }
}
extension PopulationStats {
    var total: Int64 { self.free.total + self.enslaved.total }
}
extension PopulationStats {
    mutating func startIndexCount() {
        self.occupation.removeAll(keepingCapacity: true)
        self.free.startIndexCount()
        self.enslaved.startIndexCount()
        self.employed = 0
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
