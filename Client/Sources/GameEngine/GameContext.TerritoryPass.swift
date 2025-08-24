import GameRules
import GameState

extension GameContext {
    struct TerritoryPass {
        let date: GameDate
        let player: CountryID
        let planets: RuntimeStateTable<PlanetContext>
        let cultures: RuntimeStateTable<CultureContext>
        let countries: RuntimeStateTable<CountryContext>
        let factories: RuntimeStateTable<FactoryContext>
        let pops: RuntimeStateTable<PopContext>
        let rules: GameRules
    }
}
