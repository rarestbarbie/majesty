import GameIDs

extension LaborMarket {
    struct Planetwide: LaborMarketID, Hashable {
        let id: PlanetID
        let bloc: CurrencyID
        let type: PopOccupation
    }
}
