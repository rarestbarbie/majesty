import GameIDs
import OrderedCollections

extension GameContext {
    struct PruningPass {
        let factories: OrderedSet<FactoryID>
        let pops: OrderedSet<PopID>
    }
}
