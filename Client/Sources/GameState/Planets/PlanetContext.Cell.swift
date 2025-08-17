import GameEngine
import GameEconomy
import GameEngine
import GameRules
import HexGrids

extension PlanetContext {
    struct Cell: Identifiable {
        let id: HexCoordinate
        var type: TerrainMetadata
        var tile: PlanetTile

        // Computed statistics

        private(set) var pops: [GameID<Pop>]

        init(id: HexCoordinate, type: TerrainMetadata, tile: PlanetTile) {
            self.id = id
            self.type = type
            self.tile = tile

            self.pops = []
        }
    }
}
extension PlanetContext.Cell {
    mutating func copy(from source: Self) {
        self.type = source.type
        self.tile = source.tile
    }
}
extension PlanetContext.Cell {
    mutating func startIndexCount() {
        self.pops = []
    }

    mutating func addResidentCount(pop: Pop) {
        self.pops.append(pop.id)
    }
}
