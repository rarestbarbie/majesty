import GameEngine
import GameRules

extension GameContext {
    struct ResidentPass {
        let date: GameDate
        let player: GameID<Country>
        let planets: Table<PlanetContext>
        let cultures: Table<CultureContext>
        let countries: Table<CountryContext>
        let factories: GameState.Table<FactoryContext>
        let pops: GameState.Table<PopContext>
        let rules: GameRules
    }
}
