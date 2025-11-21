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

    mutating func afterIndexCount(world: borrowing GameWorld) {
    }
}
extension PlanetGrid.Tile {
    func pickFactory(
        among factories: OrderedDictionary<FactoryType, FactoryMetadata>,
        using random: inout PseudoRandom,
    ) -> FactoryMetadata? {
        guard
        let pops: PopulationStats = self.properties?.pops,
        random.roll(
            pops.free.total / (1 + self.factoriesUnderConstruction),
            1_000_000_000
        ) else {
            return nil
        }

        let choices: [FactoryMetadata] = factories.values.filter {
            if self.factoriesAlreadyPresent.contains($0.id) {
                return false
            }
            if  $0.terrainAllowed.isEmpty {
                return true
            } else if
                $0.terrainAllowed.contains(self.terrain.id) {
                return true
            } else {
                return false
            }
        }
        return choices.randomElement(using: &random.generator)
    }

    func pickMine(
        among mines: OrderedDictionary<MineType, MineMetadata>,
        turn: inout Turn,
    ) -> (type: MineMetadata, size: Int64)? {
        // mandatory mines
        for mine: MineMetadata in mines.values {
            if !self.minesAlreadyPresent.keys.contains(mine.id), mine.spawn.isEmpty {
                return (mine, size: mine.scale)
            }
        }

        guard
        let region: RegionalProperties = self.properties,
        let factor: Fraction = region.pops.type[.Miner]?.mineExpansionFactor else {
            return nil
        }

        guard turn.random.roll(factor.n, factor.d) else {
            return nil
        }

        var existing: [(MineMetadata, size: Int64, yieldRank: Int)] = mines.values.reduce(
            into: []
        ) {
            guard
            case (size: let size, let yieldRank?)? = self.minesAlreadyPresent[$1.id] else {
                return
            }

            $0.append(($1, size: size, yieldRank: yieldRank))
        }

        // To reduce arbitrary ordering bias, give preference to higher-yield mines
        // (this means the probabilities shown in the UI are very slightly inaccurate)
        existing.sort { $0.yieldRank < $1.yieldRank }

        for (type, size, yieldRank): (MineMetadata, Int64, Int) in existing {
            guard
            let (chance, spawn): (Fraction, SpawnWeight) = type.chance(
                tile: self.geology.id,
                size: size,
                yieldRank: yieldRank
            ) else {
                continue
            }

            if  turn.random.roll(chance.n , chance.d) {
                let scale: Int64 = type.scale * spawn.size
                return (type, size: .random(in: 1 ... scale, using: &turn.random.generator))
            }
        }

        guard existing.count < 3 else {
            return nil
        }

        // we didn’t expand an existing mine, and we have room for a new one
        // we always try the one with the highest theoretical yield, even if the chance of
        // spawning it is lower than others
        var yieldMax: Double = 0
        var best: (chance: Fraction, spawn: SpawnWeight, mine: MineMetadata)?
        for mine: MineMetadata in mines.values
            where !self.minesAlreadyPresent.keys.contains(mine.id) {
            //  computing theoretical yield is expensive, so only do it for mines that can spawn
            //  on this tile’s geology
            guard
            let (chance, spawn): (Fraction, SpawnWeight) = mine.chanceNew(
                tile: self.geology.id
            ) else {
                continue
            }
            let (_, yield): (_, value: Double) = mine.yield(tile: region, turn: turn)
            if  yield > yieldMax {
                yieldMax = yield
                best = (chance, spawn, mine)
            }
        }

        if  let (chance, spawn, mine): (Fraction, SpawnWeight, MineMetadata) = best,
            turn.random.roll(chance.n , chance.d) {
            let scale: Int64 = mine.scale * spawn.size
            return (mine, size: .random(in: 1 ... scale, using: &turn.random.generator))
        }

        return nil
    }
}
