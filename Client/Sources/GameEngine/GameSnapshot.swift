import GameEconomy
import GameIDs
import OrderedCollections

@dynamicMemberLookup struct GameSnapshot: ~Copyable {
    let context: GameContext
    let markets: (
        tradeable: OrderedDictionary<Market.AssetPair, Market>,
        inelastic: LocalMarkets
    )
    let date: GameDate
}
extension GameSnapshot {
    var player: CountryProperties {
        guard
        let player: CountryContext = self.countries[self.context.player] else {
            fatalError("player country does not exist in snapshot!")
        }
        return player.properties
    }
}
extension GameSnapshot {
    subscript<T>(dynamicMember keyPath: KeyPath<GameContext, T>) -> T {
        self.context[keyPath: keyPath]
    }
}
