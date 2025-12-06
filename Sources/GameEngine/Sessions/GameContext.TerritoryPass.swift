import GameIDs
import GameRules
import GameState

extension GameContext {
    struct TerritoryPass {
        let player: CountryID
        let planets: RuntimeStateTable<PlanetContext>
        let countries: RuntimeStateTable<CountryContext>
        let factories: RuntimeStateTable<FactoryContext>
        let mines: RuntimeStateTable<MineContext>
        let pops: RuntimeStateTable<PopContext>
        let rules: GameMetadata
    }
}
