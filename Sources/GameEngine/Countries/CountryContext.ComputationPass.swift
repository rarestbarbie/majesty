import GameIDs
import GameState
import GameRules
import OrderedCollections

extension CountryContext {
    struct ComputationPass {
        let player: CountryID
        let rules: GameRules
    }
}
