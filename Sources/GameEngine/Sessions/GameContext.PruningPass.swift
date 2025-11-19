import GameIDs
import OrderedCollections

extension GameContext {
    struct PruningPass {
        let factories: OrderedSet<FactoryID>
        let mines: OrderedSet<MineID>
        let pops: OrderedSet<PopID>
    }
}
extension GameContext.PruningPass {
    func contains(_ lei: LEI) -> Bool {
        switch lei {
        case .factory(let id): self.factories.contains(id)
        case .pop(let id): self.pops.contains(id)
        }
    }
}
