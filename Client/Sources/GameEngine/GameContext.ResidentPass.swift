import GameState
import GameRules

extension GameContext {
    struct ResidentPass {
        let player: CountryID
        let planets: RuntimeContextTable<PlanetContext>
        let cultures: RuntimeContextTable<CultureContext>
        let countries: RuntimeContextTable<CountryContext>
        let factories: RuntimeStateTable<FactoryContext>
        let pops: RuntimeStateTable<PopContext>
        let rules: GameRules
    }
}
