import D
import GameIDs
import GameUI

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
extension PopulationStats {
    func tooltip(culture: String) -> Tooltip? {
        let share: Int64 = self.free.cultures[culture]
            ?? self.enslaved.cultures[culture]
            ?? 0
        let total: Int64 = self.total

        if  total == 0 {
            return nil
        }

        return .instructions(style: .borderless) {
            $0[culture] = (Double.init(share) / Double.init(total))[%3]
        }
    }
    func tooltip(popType: PopType) -> Tooltip? {
        let share: Int64 = self.type[popType] ?? 0
        let total: Int64 = self.free.total

        if  total == 0 {
            return nil
        }

        return .instructions(style: .borderless) {
            $0[popType.plural] = (Double.init(share) / Double.init(total))[%3]
        }
    }
}
