import GameEconomy
import OrderedCollections

@dynamicMemberLookup struct GameSnapshot: ~Copyable {
    let context: GameContext
    let markets: OrderedDictionary<Market.AssetPair, Market>
}
extension GameSnapshot {
    subscript<T>(dynamicMember keyPath: KeyPath<GameContext, T>) -> T {
        self.context[keyPath: keyPath]
    }
}
