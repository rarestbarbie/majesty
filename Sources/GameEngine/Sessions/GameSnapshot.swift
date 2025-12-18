import D
import Fraction
import GameConditions
import GameEconomy
import GameIDs
import GameRules
import GameState
import GameUI
import HexGrids
import OrderedCollections

struct GameSnapshot: ~Copyable {
    let player: CountryID

    let currencies: OrderedDictionary<CurrencyID, Currency>
    let countries: RuntimeContextTable<CountryContext>
    let planets: RuntimeContextTable<PlanetContext>

    let rules: GameMetadata

    let markets: (
        tradeable: OrderedDictionary<WorldMarket.ID, WorldMarket>,
        segmented: OrderedDictionary<LocalMarket.ID, LocalMarket>
    )
    let bank: Bank
    let date: GameDate
}
extension GameSnapshot {
    var playerCountry: Country {
        guard
        let player: CountryContext = self.countries[self.player] else {
            fatalError("player country does not exist in snapshot!")
        }
        return player.state
    }
}
