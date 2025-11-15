import D
import GameIDs
import GameUI

struct PopulationStats {
    var type: [PopType: Row]
    var free: PopulationStratum
    var enslaved: PopulationStratum
    var employed: Int64
}
extension PopulationStats {
    init() {
        self.init(type: [:], free: .init(), enslaved: .init(), employed: 0)
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
        self.employed = 0
    }

    mutating func addResidentCount(_ pop: Pop, _ stats: Pop.Stats) {
        {
            $0.count += pop.z.size
            $0.employed += stats.employedBeforeEgress
        } (&self.type[pop.type, default: .zero])

        if pop.type.stratum <= .Ward {
            self.enslaved.addResidentCount(pop)
        } else {
            self.employed += stats.employedBeforeEgress
            self.free.addResidentCount(pop)
        }
    }
}
extension PopulationStats {
    func tooltip(culture: String) -> Tooltip? {
        let free: Int64? = self.free.cultures[culture]
        let enslaved: Int64? = self.enslaved.cultures[culture]

        let share: Int64
        let total: Int64

        if  let free: Int64 {
            share = free
            total = self.free.total
        } else if
            let enslaved: Int64 {
            share = enslaved
            total = self.enslaved.total
        } else {
            return nil
        }

        if  total == 0 {
            return nil
        }

        return .instructions(style: .borderless) {
            $0[culture] = (Double.init(share) / Double.init(total))[%3]
            $0[>] {
                $0["Free"] = free?[/3]
                $0["Enslaved"] = enslaved?[/3]
            }
        }
    }
    func tooltip(popType: PopType) -> Tooltip? {
        let share: Row = self.type[popType] ?? .zero
        let total: Int64 = self.free.total

        if  total == 0 {
            return nil
        }

        return .instructions(style: .borderless) {
            let n: Double = Double.init(share.count)
            let d: Double = Double.init(total)
            $0[popType.plural] = (n / d)[%3]
            $0[>] {
                $0["Unemployment rate", (-)] = (Double.init(share.unemployed) / n)[%3]
            }
        }
    }
}
