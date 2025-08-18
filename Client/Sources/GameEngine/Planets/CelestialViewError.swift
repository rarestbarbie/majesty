import GameState

enum CelestialViewError: Error {
    case noSuchIndex(Int)
    case noSuchWorld(GameID<Planet>)
}
