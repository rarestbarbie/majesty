import GameEconomy
import GameIDs

extension TradeRoute {
    struct ID: Equatable, Hashable {
        let partner: CurrencyID
        let asset: WorldMarket.Asset
    }
}
