import GameEconomy
import GameEngine
import GameRules
import HexGrids

extension PlanetContext {
    struct Cell: Identifiable {
        let id: HexCoordinate
        var type: TerrainMetadata
        var tile: PlanetTile
    }
}
extension PlanetContext.Cell {
    mutating func copy(from source: Self) {
        self.type = source.type
        self.tile = source.tile
    }
}
