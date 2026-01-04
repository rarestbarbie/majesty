extension GameAPI {
    enum Symbol: String {
        case save
        /// Load the game state from a file.
        case load
        case loadTerrain
        case editTerrain
        case saveTerrain

        case call
        /// Sequence a player event.
        case push

        case gregorian
        /// Render a celestial orbit to a `[Float32]` array of coordinates.
        case orbit

        case openPlanet

        /// Switch to the Infrastructure screen and return its initial state.
        case openInfrastructure
        /// Switch to the Production screen and return its initial state.
        case openProduction
        /// Switch to the Population screen and return its initial state.
        case openPopulation
        /// Switch to the Budget screen and return its initial state.
        case openBudget
        /// Switch to the Trade screen and return its initial state.
        case openTrade

        case closeScreen

        case minimap
        case minimapTile
        /// Open a celestial view and return its initial state.
        case view

        case contextMenu
        case tooltip
    }
}
extension GameAPI.Symbol: CustomStringConvertible {
    var description: String { self.rawValue }
}
