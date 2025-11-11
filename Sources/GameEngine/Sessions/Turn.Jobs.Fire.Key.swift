import GameIDs

extension Turn.Jobs.Fire {
    enum Key: Hashable {
        case factory(PopType, FactoryID)
        case mine(PopType, MineID)
    }
}
