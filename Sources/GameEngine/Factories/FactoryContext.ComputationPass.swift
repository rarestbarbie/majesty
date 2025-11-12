import GameIDs
import GameState
import GameRules

extension FactoryContext {
    struct ComputationPass {
        let player: CountryID
        let rules: GameRules

        let planets: RuntimeContextTable<PlanetContext>
    }
}
