import Fraction
import GameEconomy
import GameRules
import GameIDs
import GameTerrain
import HexGrids
import OrderedCollections
import Random

extension PlanetGrid {
    struct Tile: Identifiable {
        let id: Address
        var properties: RegionalProperties?

        var name: String?
        var terrain: TerrainMetadata
        var geology: GeologicalMetadata

        // Computed statistics
        private(set) var factoriesUnderConstruction: Int64
        private(set) var factoriesAlreadyPresent: Set<FactoryType>
        private(set) var factories: [FactoryID]

        private(set) var minesAlreadyPresent: [MineType: (size: Int64, yieldRank: Int?)]
        private(set) var mines: [MineID]

        init(
            id: Address,
            name: String?,
            terrain: TerrainMetadata,
            geology: GeologicalMetadata,
        ) {
            self.id = id
            self.properties = nil

            self.name = name
            self.terrain = terrain
            self.geology = geology

            self.factoriesUnderConstruction = 0
            self.factoriesAlreadyPresent = []
            self.factories = []

            self.minesAlreadyPresent = [:]
            self.mines = []
        }
    }
}
extension PlanetGrid.Tile {
    var governedBy: CountryProperties? { self.properties?.governedBy }
    var occupiedBy: CountryProperties? { self.properties?.occupiedBy }

    var pops: PopulationStats { self.properties?.pops ?? .init() }
}
extension PlanetGrid.Tile {
    mutating func copy(from source: Self) {
        self.name = source.name
        self.terrain = source.terrain
        self.geology = source.geology
    }
}
extension PlanetGrid.Tile {
    mutating func update(
        governedBy: CountryProperties,
        occupiedBy: CountryProperties,
    ) {
        if  let properties: RegionalProperties = self.properties {
            properties.governedBy = governedBy
            properties.occupiedBy = occupiedBy
        } else {
            self.properties = .init(
                id: self.id,
                governedBy: governedBy,
                occupiedBy: occupiedBy
            )
        }
    }

    mutating func startIndexCount() {
        self.factoriesUnderConstruction = 0
        self.factoriesAlreadyPresent.removeAll(keepingCapacity: true)
        self.factories.removeAll(keepingCapacity: true)

        self.minesAlreadyPresent.removeAll(keepingCapacity: true)
        self.mines.removeAll(keepingCapacity: true)

        self.properties?.startIndexCount()
    }

    mutating func addResidentCount(_ pop: Pop, _ stats: Pop.Stats) {
        self.properties?.addResidentCount(pop, stats)
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
        self.minesAlreadyPresent[mine.type] = (mine.z.size, mine.z.yieldRank)
    }
}
extension PlanetGrid.Tile {
    func pickFactory(
        among factories: OrderedDictionary<FactoryType, FactoryMetadata>,
        using random: inout PseudoRandom,
    ) -> FactoryType? {
        guard
        let pops: PopulationStats = self.properties?.pops,
        random.roll(
            pops.free.total / (1 + self.factoriesUnderConstruction),
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
    ) -> [(type: MineType, size: Int64)] {
        // mandatory mines
        for (missing, mine): (MineType, MineMetadata) in mines {
            if !self.minesAlreadyPresent.keys.contains(missing), mine.spawn.isEmpty {
                return [(type: missing, size: mine.scale)]
            }
        }

        guard
        let miners: PopulationStats.Row = self.properties?.pops.type[.Miner],
        let factor: Fraction = miners.mineExpansionFactor else {
            return []
        }

        guard random.roll(factor.n, factor.d) else {
            return []
        }

        return mines.reduce(into: []) {
            let current: (size: Int64, yieldRank: Int)
            switch self.minesAlreadyPresent[$1.key] {
            case (size: let size, let yieldRank?)?:
                current = (size, yieldRank)

            case (size: _, nil)?:
                return

            case nil:
                current = (0, 0)
            }

            guard
            let (chance, spawn): (Fraction, SpawnWeight) = $1.value.chance(
                size: current.size,
                tile: self.geology.id,
                yieldRank: current.yieldRank
            ) else {
                return
            }

            if  random.roll(chance.n , chance.d) {
                let scale: Int64 = $1.value.scale * spawn.size
                let size: Int64 = .random(in: 1 ... scale, using: &random.generator)
                $0.append(($1.key, size: size))
            }
        }
    }
}
