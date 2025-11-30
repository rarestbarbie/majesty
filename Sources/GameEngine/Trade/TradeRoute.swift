import GameEconomy
import GameIDs

struct TradeRoute {
    let id: ID
    let started: GameDate
    var y: Activity
    var z: Activity
}
extension TradeRoute {
    init(started: GameDate, partner: CurrencyID, asset: WorldMarket.Asset) {
        self.init(
            id: .init(partner: partner, asset: asset),
            started: started,
            y: .zero,
            z: .zero
        )
    }
}
extension TradeRoute: Turnable {
    mutating func turn() {
        self.z = .zero
    }
}
