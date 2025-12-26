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
        let markets: (
            tradeable: OrderedDictionary<WorldMarket.ID, WorldMarket>,
            segmented: OrderedDictionary<LocalMarket.ID, LocalMarket>
        )
        let planets: OrderedDictionary<PlanetID, PlanetSnapshot>
        let tiles: [Address: PlanetGrid.TileSnapshot]
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
