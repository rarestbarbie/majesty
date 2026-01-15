import OrderedCollections
import GameClock
import GameEconomy
import GameIDs
import GameRules
import GameState

extension GameUI {
    struct CacheContext {
        let currencies: OrderedDictionary<CurrencyID, Currency>
        let countries: OrderedDictionary<CountryID, Country>
        let planets: OrderedDictionary<PlanetID, PlanetSnapshot>
        let tiles: [Address: TileSnapshot]

        let localMarkets: OrderedDictionary<LocalMarket.ID, LocalMarket>
        let worldMarkets: OrderedDictionary<WorldMarket.ID, WorldMarket>
        let ledger: EconomicLedger
        let bank: Bank
        let date: GameDate

        let player: CountryID
        let speed: GameSpeed
        let rules: GameMetadata
    }
}
extension GameUI.CacheContext {
    var playerCountry: Country {
        guard
        let player: Country = self.countries[self.player] else {
            fatalError("player country does not exist in snapshot!")
        }
        return player
    }
}
