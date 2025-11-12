import GameIDs
import GameState
import GameRules

extension MineContext {
    struct ComputationPass {
        let player: CountryID
        let rules: GameRules

        let planets: RuntimeContextTable<PlanetContext>
    }
}
