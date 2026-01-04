import GameIDs

extension InfrastructureReport {
    struct Filters: Hashable {
        var location: Address?
    }
}
extension InfrastructureReport.Filters: PersistentLayeredSelectionFilter {
    typealias Subject = BuildingSnapshot
    typealias Layer = InfrastructureReport.Filter

    static var all: Self {
        .init(location: nil)
    }

    static func += (self: inout Self, layer: InfrastructureReport.Filter) {
        switch layer {
        case .location(let filter): self.location = filter
        }
    }

    static func ~= (self: Self, value: BuildingSnapshot) -> Bool {
        if  let location: Address = self.location, location != value.tile {
            return false
        }

        return true
    }
}
