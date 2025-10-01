import GameEconomy
import GameRules
import GameState
import GameTerrain
import HexGrids

extension PlanetGrid {
    struct Tile: Identifiable {
        let id: HexCoordinate
        var name: String?
        var terrain: TerrainMetadata
        var geology: GeologicalMetadata

        var governedBy: CountryProperties?
        var occupiedBy: CountryProperties?

        // Computed statistics

        private(set) var pops: [PopID]
        private(set) var population: Int64
        private(set) var weighted: (
            mil: Double,
            con: Double
        )

        init(
            id: HexCoordinate,
            name: String?,
            terrain: TerrainMetadata,
            geology: GeologicalMetadata,
        ) {
            self.id = id
            self.name = name
            self.terrain = terrain
            self.geology = geology

            self.governedBy = nil
            self.occupiedBy = nil

            self.pops = []
            self.population = 0
            self.weighted.mil = 0
            self.weighted.con = 0
        }
    }
}
extension PlanetGrid.Tile {
    mutating func copy(from source: Self) {
        self.name = source.name
        self.terrain = source.terrain
        self.geology = source.geology
    }
}
extension PlanetGrid.Tile {
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
