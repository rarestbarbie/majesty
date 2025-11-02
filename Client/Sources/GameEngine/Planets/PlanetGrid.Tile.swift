import GameEconomy
import GameRules
import GameIDs
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
        private(set) var factoriesAlreadyPresent: Set<FactoryType>
        private(set) var factories: [FactoryID]

        private(set) var minesAlreadyPresent: Set<MineType>
        private(set) var mines: [MineID]

        private(set) var pops: PopulationStats

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
            self.factoriesAlreadyPresent = []
            self.factories = []

            self.minesAlreadyPresent = []
            self.mines = []

            self.pops = .init()
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
        self.factoriesUnderConstruction = 0
        self.factoriesAlreadyPresent.removeAll(keepingCapacity: true)
        self.factories.removeAll(keepingCapacity: true)

        self.minesAlreadyPresent.removeAll(keepingCapacity: true)
        self.mines.removeAll(keepingCapacity: true)

        self.pops.startIndexCount()
    }

    mutating func addResidentCount(_ pop: Pop) {
        self.pops.addResidentCount(pop)
    }
    mutating func addResidentCount(_ factory: Factory) {
        self.factories.append(factory.id)
        self.factoriesAlreadyPresent.insert(factory.type)

        if factory.size.level == 0 {
            self.factoriesUnderConstruction += 1
        }
    }
    mutating func addResidentCount(_ mine: Mine) {
        self.mines.append(mine.id)
        self.minesAlreadyPresent.insert(mine.type)
    }
}
extension PlanetGrid.Tile {
    func pickFactory(
        among factories: OrderedDictionary<FactoryType, FactoryMetadata>,
        using random: inout PseudoRandom,
    ) -> FactoryType? {
        guard random.roll(
            self.pops.free.total / (1 + self.factoriesUnderConstruction),
            1_000_000_000
        ) else {
            return nil
        }

        let choices: [FactoryType] = factories.reduce(into: []) {
            if self.factoriesAlreadyPresent.contains($1.key) {
                return
            }
            if  $1.value.terrainAllowed.isEmpty {
                $0.append($1.key)
            } else if
                $1.value.terrainAllowed.contains(self.terrain.id) {
                $0.append($1.key)
            }
        }
        return choices.randomElement(using: &random.generator)
    }
    func pickMine(
        among mines: OrderedDictionary<MineType, MineMetadata>,
        using random: inout PseudoRandom,
    ) -> MineType? {
        // mandatory mines
        for (missing, mine): (MineType, MineMetadata) in mines {
            if !self.minesAlreadyPresent.contains(missing), mine.geology.isEmpty {
                return missing
            }
        }

        guard random.roll(
            self.pops.free.total,
            1_000_000_000
        ) else {
            return nil
        }

        let choices: [(type: MineType, chance: Int64)] = mines.reduce(into: []) {
            if self.minesAlreadyPresent.contains($1.key) {
                return
            }
            if  let chance: Int64 = $1.value.geology[self.geology.id] {
                $0.append(($1.key, chance))
            }
        }
        let sampler: RandomWeightedSampler<[(MineType, chance: Int64)], Double>? = .init(
            choices: choices
        ) {
            Double.init($0.chance)
        }
        return sampler.map { choices[$0.next(using: &random.generator)].type }

    }
}
