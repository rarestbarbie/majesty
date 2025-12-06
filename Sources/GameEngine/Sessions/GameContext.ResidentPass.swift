import GameIDs
import GameState
import GameRules

extension GameContext {
    struct ResidentPass {
        let player: CountryID
        let planets: RuntimeContextTable<PlanetContext>
        let countries: RuntimeContextTable<CountryContext>
        let buildings: RuntimeStateTable<BuildingContext>
        let factories: RuntimeStateTable<FactoryContext>
        let mines: RuntimeStateTable<MineContext>
        let pops: RuntimeStateTable<PopContext>
        let rules: GameMetadata
    }
}
