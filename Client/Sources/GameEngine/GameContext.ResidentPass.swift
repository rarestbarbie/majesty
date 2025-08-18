import GameState
import GameRules

extension GameContext {
    struct ResidentPass {
        let date: GameDate
        let player: GameID<Country>
        let planets: Table<PlanetContext>
        let cultures: Table<CultureContext>
        let countries: Table<CountryContext>
        let factories: GameSnapshot.Table<FactoryContext>
        let pops: GameSnapshot.Table<PopContext>
        let rules: GameRules
    }
}
