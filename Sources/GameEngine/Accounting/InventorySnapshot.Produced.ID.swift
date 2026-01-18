import GameIDs

extension InventorySnapshot.Produced {
    enum ID: Equatable, Hashable {
        case o(Resource)
        case m(MineVein)
    }
}
extension InventorySnapshot.Produced.ID {
    var line: InventoryLine {
        switch self {
        case .o(let id): .o(id)
        case .m(let id): .m(id)
        }
    }
    var mine: MineID? {
        switch self {
        case .o: nil
        case .m(let id): id.mine
        }
    }
    var resource: Resource {
        switch self {
        case .o(let id): id
        case .m(let id): id.resource
        }
    }
}
