import GameIDs

protocol LaborMarketID: Hashable {
    var type: PopOccupation { get }
}
