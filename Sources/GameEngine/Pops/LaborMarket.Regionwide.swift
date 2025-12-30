import GameIDs

extension LaborMarket {
    struct Regionwide: LaborMarketID, Hashable {
        let id: Address
        let type: PopOccupation
    }
}
