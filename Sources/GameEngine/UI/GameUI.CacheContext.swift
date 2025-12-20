import OrderedCollections
import GameEconomy
import GameIDs
import GameRules
import GameState
import GameUI

extension GameUI {
    struct CacheContext {
        let currencies: OrderedDictionary<CurrencyID, Currency>
        let countries: OrderedDictionary<CountryID, Country>
        let markets: (
            tradeable: OrderedDictionary<WorldMarket.ID, WorldMarket>,
            segmented: OrderedDictionary<LocalMarket.ID, LocalMarket>
        )
        let orbits: OrderedDictionary<PlanetID, CelestialMotion>
        let bank: Bank
        let rules: GameMetadata
    }
}
extension GameUI.CacheContext {
    func tooltipExplainPrice(
        _ object: some LegalEntitySnapshot,
        _ line: InventoryLine,
    ) -> Tooltip? {
        let resource: Resource = line.resource
        let market: (
            segmented: LocalMarketSnapshot?,
            tradeable: WorldMarket.State?
        ) = (
            self.markets.segmented[resource / object.state.tile]?.snapshot(object.region),
            self.markets.tradeable[resource / object.region.currency.id]?.state
        )

        return object.tooltipExplainPrice(line, market: market)
    }
}
