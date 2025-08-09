import GameEngine
import GameRules

public struct GameState {
    let date: GameDate
    let player: GameID<Country>
    let planets: Table<PlanetContext>
    let cultures: Table<CultureContext>
    let countries: Table<CountryContext>
    let factories: Table<FactoryContext>
    let pops: Table<PopContext>
    let rules: GameRules
}
