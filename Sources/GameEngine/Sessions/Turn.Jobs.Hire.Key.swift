import GameIDs

extension Turn.Jobs.Hire {
    struct Key: Hashable {
        let market: Market
        let type: PopOccupation
    }
}
