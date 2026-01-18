import GameIDs

extension InventorySnapshot.Consumed {
    enum ID: Equatable, Hashable {
        case l(Resource)
        case e(Resource)
        case x(Resource)
    }
}
extension InventorySnapshot.Consumed.ID {
    var resource: Resource {
        switch self {
        case .l(let id): id
        case .e(let id): id
        case .x(let id): id
        }
    }

    var line: InventoryLine {
        switch self {
        case .l(let id): .l(id)
        case .e(let id): .e(id)
        case .x(let id): .x(id)
        }
    }

    static func ~= (tier: ResourceTierIdentifier, self: Self) -> Bool {
        switch (tier, self) {
        case (.l, .l): true
        case (.e, .e): true
        case (.x, .x): true
        default: false
        }
    }
}
