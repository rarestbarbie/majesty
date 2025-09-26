import GameEconomy
import GameState
import OrderedCollections

@dynamicMemberLookup struct GameSnapshot: ~Copyable {
    let context: GameContext
    let markets: (
        tradeable: OrderedDictionary<Market.AssetPair, Market>,
        inelastic: LocalMarkets<PopID>
    )
    let date: GameDate
}
extension GameSnapshot {
    subscript<T>(dynamicMember keyPath: KeyPath<GameContext, T>) -> T {
        self.context[keyPath: keyPath]
    }
}
