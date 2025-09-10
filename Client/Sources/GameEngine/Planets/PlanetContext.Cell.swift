import GameEconomy
import GameRules
import GameState
import GameTerrain
import HexGrids

extension PlanetContext {
    struct Cell: Identifiable {
        let id: HexCoordinate
        var type: TerrainMetadata
        var tile: PlanetTile

        // Computed statistics

        private(set) var pops: [PopID]
        private(set) var population: Int64
        private(set) var weighted: (
            mil: Double,
            con: Double
        )

        init(id: HexCoordinate, type: TerrainMetadata, tile: PlanetTile) {
            self.id = id
            self.type = type
            self.tile = tile

            self.pops = []
            self.population = 0
            self.weighted.mil = 0
            self.weighted.con = 0
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
        self.population = 0
        self.weighted.mil = 0
        self.weighted.con = 0
    }

    mutating func addResidentCount(pop: Pop) {
        let weight: Double = .init(pop.today.size)
        self.pops.append(pop.id)
        self.population += pop.today.size
        self.weighted.mil += pop.today.mil * weight
        self.weighted.con += pop.today.con * weight
    }
}
