import GameIDs
import GameState
import GameRules

extension PopContext {
    struct ComputationPass {
        let player: CountryID
        let rules: GameMetadata

        let planets: RuntimeContextTable<PlanetContext>
        let factories: RuntimeStateTable<FactoryContext>
        let mines: RuntimeStateTable<MineContext>
    }
}
