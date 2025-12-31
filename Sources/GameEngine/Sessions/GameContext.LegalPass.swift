import GameIDs
import GameState
import GameRules

extension GameContext {
    struct LegalPass {
        let buildings: DynamicContextTable<BuildingContext>
        let factories: DynamicContextTable<FactoryContext>
        let pops: DynamicContextTable<PopContext>
    }
}
