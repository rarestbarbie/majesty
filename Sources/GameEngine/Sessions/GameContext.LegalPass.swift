import GameIDs
import GameState
import GameRules

extension GameContext {
    struct LegalPass {
        let countries: RuntimeStateTable<CountryContext>
        let buildings: RuntimeStateTable<BuildingContext>
        let factories: RuntimeStateTable<FactoryContext>
        let pops: RuntimeStateTable<PopContext>
    }
}
