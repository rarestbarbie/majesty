import GameIDs
import GameState
import GameRules

extension FactoryContext {
    struct ComputationPass {
        let player: CountryID
        let rules: GameMetadata
        let tiles: RuntimeContextTable<TileContext>
    }
}
