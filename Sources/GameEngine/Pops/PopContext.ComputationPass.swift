import GameIDs
import GameState
import GameRules

extension PopContext {
    struct ComputationPass {
        let player: CountryID
        let rules: GameMetadata
        let tiles: RuntimeContextTable<TileContext>
        let factories: RuntimeStateTable<FactoryContext>
        let mines: RuntimeStateTable<MineContext>
    }
}
