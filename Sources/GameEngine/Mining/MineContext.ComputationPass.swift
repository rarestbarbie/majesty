import GameIDs
import GameState
import GameRules

extension MineContext {
    struct ComputationPass {
        let player: CountryID
        let rules: GameMetadata
        let tiles: RuntimeContextTable<TileContext>
    }
}
