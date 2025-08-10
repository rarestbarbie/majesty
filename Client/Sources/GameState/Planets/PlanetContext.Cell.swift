import GameEconomy
import GameEngine
import GameRules
import HexGrids

extension PlanetContext {
    struct Cell: Identifiable {
        let id: HexCoordinate
        let type: TerrainMetadata
        let tile: PlanetTile
    }
}
