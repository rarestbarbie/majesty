import GameIDs

extension GameMap.Jobs.Fire {
    enum Key: Hashable {
        case factory(PopType, FactoryID)
        case mine(PopType, MineID)
    }
}
