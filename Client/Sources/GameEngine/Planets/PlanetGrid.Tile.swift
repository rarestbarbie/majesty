import GameEconomy
import GameRules
import GameState
import GameTerrain
import HexGrids
import OrderedCollections
import Random

extension PlanetGrid {
    struct Tile: Identifiable {
        let id: HexCoordinate
        var name: String?
        var terrain: TerrainMetadata
        var geology: GeologicalMetadata

        var governedBy: CountryProperties?
        var occupiedBy: CountryProperties?

        // Computed statistics
        private(set) var factoriesUnderConstruction: Int64
        private(set) var factories: [FactoryID]
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

            self.factoriesUnderConstruction = 0
            self.factories = []
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
        self.factories = []
        self.pops = []
        self.population = 0
        self.weighted.mil = 0
        self.weighted.con = 0
    }

    mutating func addResidentCount(_ pop: Pop) {
        let weight: Double = .init(pop.today.size)
        self.pops.append(pop.id)
        self.population += pop.today.size
        self.weighted.mil += pop.today.mil * weight
        self.weighted.con += pop.today.con * weight
    }
    mutating func addResidentCount(_ factory: Factory) {
        self.factories.append(factory.id)

        if factory.size.level == 0 {
            self.factoriesUnderConstruction += 1
        }
    }
}
extension PlanetGrid.Tile {
    func pickFactory(
        among factories: OrderedDictionary<FactoryType, FactoryMetadata>,
        using random: inout PseudoRandom,
        where filter: (FactoryType, HexCoordinate) throws -> Factory.Section?,
    ) rethrows -> Factory.Section? {
        guard random.roll(self.population / (1 + self.factoriesUnderConstruction), 1_000_000_000) else {
            return nil
        }

        let choices: [Factory.Section] = try factories.keys.reduce(into: []) {
            if  let section: Factory.Section = try filter($1, self.id) {
                $0.append(section)
            }
        }
        return choices.randomElement(using: &random.generator)
    }
}
