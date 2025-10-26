import GameIDs
import OrderedCollections

extension GameContext {
    struct PruningPass {
        let factories: OrderedSet<FactoryID>
        let mines: OrderedSet<MineID>
        let pops: OrderedSet<PopID>
    }
}
