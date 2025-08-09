import GameEconomy
import GameEngine
import GameRules

extension PlanetContext {
    struct Cell: Identifiable {
        let id: HexCoordinate
        let type: TerrainMetadata
        let tile: PlanetTile
    }
}
