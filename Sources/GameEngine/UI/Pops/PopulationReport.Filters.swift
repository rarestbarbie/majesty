import GameIDs

extension PopulationReport {
    struct Filters: Hashable {
        var location: Address?
        var sex: Sex?
    }
}
extension PopulationReport.Filters: PersistentLayeredSelectionFilter {
    typealias Subject = PopSnapshot
    typealias Layer = PopulationReport.Filter

    static var all: Self {
        .init(location: nil, sex: nil)
    }

    static func += (self: inout Self, layer: PopulationReport.Filter) {
        switch layer {
        case .sex(let filter): self.sex = filter
        case .location(let filter): self.location = filter
        }
    }

    static func ~= (self: Self, value: PopSnapshot) -> Bool {
        if  let location: Address = self.location, location != value.tile {
            return false
        }
        if  let sex: Sex = self.sex, sex != value.type.gender.sex {
            return false
        }

        return true
    }
}
