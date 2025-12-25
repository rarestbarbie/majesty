import GameIDs

extension ProductionReport {
    struct Filters: Hashable {
        var location: Address?
    }
}
extension ProductionReport.Filters: PersistentSelectionFilter {
    typealias Subject = FactorySnapshot
    typealias Layer = ProductionReport.Filter

    static var all: Self {
        .init(location: nil)
    }

    static func += (self: inout Self, layer: ProductionReport.Filter) {
        switch layer {
        case .location(let filter): self.location = filter
        }
    }

    static func ~= (self: Self, value: FactorySnapshot) -> Bool {
        if  let location: Address = self.location, location != value.state.tile {
            return false
        }

        return true
    }
}
