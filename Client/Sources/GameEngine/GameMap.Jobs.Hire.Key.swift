import GameIDs

extension GameMap.Jobs.Hire {
    struct Key: Hashable {
        let location: Location
        let type: PopType
    }
}
