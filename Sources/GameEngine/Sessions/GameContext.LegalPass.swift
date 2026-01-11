import GameIDs
import GameState
import GameRules

extension GameContext {
    struct LegalPass {
        let countries: RuntimeContextTable<CountryContext>
        let buildings: DynamicContextTable<BuildingContext>
        let factories: DynamicContextTable<FactoryContext>
        let pops: DynamicContextTable<PopContext>
    }
}
