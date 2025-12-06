import GameIDs

extension Turn.Jobs.Fire {
    enum Key: Hashable {
        case factory(PopOccupation, FactoryID)
        case mine(PopOccupation, MineID)
    }
}
