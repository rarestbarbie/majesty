import GameIDs

extension Turn.Jobs.Hire {
    struct Key: Hashable {
        let location: Location
        let type: PopType
    }
}
