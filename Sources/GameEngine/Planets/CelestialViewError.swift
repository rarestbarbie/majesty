import GameIDs

enum CelestialViewError: Error {
    case noSuchIndex(Int)
    case noSuchWorld(PlanetID)
}
