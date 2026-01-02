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
        private(set) var properties: RegionalProperties?
        private(set) var authority: RegionalAuthority?
        private var stats: RegionalStats

        var name: String?
        var terrain: TerrainMetadata
        var geology: GeologicalMetadata

        // Computed statistics
        private(set) var buildingsAlreadyPresent: Set<BuildingType>
        private(set) var buildings: [BuildingID]

        private(set) var factoriesUnderConstruction: Int64
        private(set) var factoriesAlreadyPresent: Set<FactoryType>
        private(set) var factories: [FactoryID]

        private(set) var minesAlreadyPresent: [MineType: (size: Int64, yieldRank: Int?)]
        private(set) var mines: [MineID]
        private var criticalShortages: [Resource]

        init(
            id: Address,
            name: String?,
            terrain: TerrainMetadata,
            geology: GeologicalMetadata,
        ) {
            self.id = id
            self.properties = nil
            self.authority = nil
            self.stats = .init()

            self.name = name
            self.terrain = terrain
            self.geology = geology

            self.buildingsAlreadyPresent = []
            self.buildings = []

            self.factoriesUnderConstruction = 0
            self.factoriesAlreadyPresent = []
            self.factories = []

            self.minesAlreadyPresent = [:]
            self.mines = []

            self.criticalShortages = []
        }
    }
}
extension PlanetGrid.Tile {
    var governedBy: CountryID? { self.authority?.governedBy }
    var occupiedBy: CountryID? { self.authority?.occupiedBy }

    var pops: PopulationStats { self.stats.pops }

    var snapshot: PlanetGrid.TileSnapshot {
        .init(
            id: self.id,
            name: self.name,
            properties: self.properties,
            terrain: self.terrain,
            geology: self.geology
        )
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
    mutating func update(
        governedBy: CountryID,
        occupiedBy: CountryID,
        suzerain: CountryID?,
        properties: CountryProperties,
    ) {
        self.authority = .init(
            id: self.id,
            governedBy: governedBy,
            occupiedBy: occupiedBy,
            suzerain: suzerain,
            country: properties
        )
    }

    mutating func startIndexCount() {
        self.buildingsAlreadyPresent.removeAll(keepingCapacity: true)
        self.buildings.removeAll(keepingCapacity: true)

        self.factoriesUnderConstruction = 0
        self.factoriesAlreadyPresent.removeAll(keepingCapacity: true)
        self.factories.removeAll(keepingCapacity: true)

        self.minesAlreadyPresent.removeAll(keepingCapacity: true)
        self.mines.removeAll(keepingCapacity: true)

        self.stats.startIndexCount()
    }

    mutating func addResidentCount(_ pop: Pop, _ stats: Pop.Stats) -> RegionalAuthority? {
        self.stats.pops.addResidentCount(pop, stats)
        // this should not return the ``RegionalProperties``, that has not been published yet
        return self.authority
    }
    mutating func addResidentCount(_ building: Building) -> RegionalAuthority? {
        self.buildings.append(building.id)
        self.buildingsAlreadyPresent.insert(building.type)
        return self.authority
    }
    mutating func addResidentCount(_ factory: Factory) -> RegionalAuthority? {
        self.factories.append(factory.id)
        self.factoriesAlreadyPresent.insert(factory.type)

        if factory.size.level == 0 {
            self.factoriesUnderConstruction += 1
        }

        return self.authority
    }
    mutating func addResidentCount(_ mine: Mine) {
        self.mines.append(mine.id)
        self.minesAlreadyPresent[mine.type] = (mine.z.size, mine.z.yieldRank)
    }

    mutating func afterIndexCount(world: borrowing GameWorld) {
        guard let region: RegionalAuthority = self.authority else {
            return
        }

        self.properties = .init(
            id: self.id,
            name: self.name ?? "",
            pops: self.stats.pops,
            occupiedBy: region.occupiedBy,
            governedBy: region.governedBy,
            suzerain: region.suzerain,
            country: region.country,
        )

        self.criticalShortages = region.country.criticalResources.filter {
            if  let localMarket: LocalMarket = world.segmentedMarkets[$0 / self.id],
                    localMarket.today.supply == 0,
                    localMarket.today.demand > 0 {
                return true
            } else {
                return false
            }
        }
    }
}
extension PlanetGrid.Tile {
    func pickBuilding(
        among buildings: OrderedDictionary<BuildingType, BuildingMetadata>,
        using random: inout PseudoRandom,
    ) -> BuildingMetadata? {
        guard case _? = self.properties else {
            // do not build on uninhabited tiles
            return nil
        }
        // TODO: enforce terrain restrictions...
        // mandatory buildings
        for building: BuildingMetadata in buildings.values where building.required {
            if !self.buildingsAlreadyPresent.contains(building.id) {
                return building
            }
        }
        return nil
    }
}
extension PlanetGrid.Tile {
    private func filter(
        factories: OrderedDictionary<FactoryType, FactoryMetadata>,
        where predicate: (FactoryMetadata) -> Bool
    ) -> [FactoryMetadata] {
        factories.values.filter {
            if self.factoriesAlreadyPresent.contains($0.id) {
                return false
            }
            if  $0.terrainAllowed.isEmpty {
                return predicate($0)
            } else if
                $0.terrainAllowed.contains(self.terrain.id) {
                return predicate($0)
            } else {
                return false
            }
        }
    }

    func pickFactory(
        among factories: OrderedDictionary<FactoryType, FactoryMetadata>,
        using random: inout PseudoRandom,
    ) -> FactoryMetadata? {
        guard
        let region: RegionalProperties = self.properties else {
            return nil
        }
        let pops: PopulationStats = region.pops

        let chance: Int64
        switch pops.free.total {
        case ...0:
            return nil
        case 1 ..< 50_000:
            chance = 1
        case 50_000 ..< 2_000_000:
            chance = 2
        case 2_000_000 ..< 10_000_000:
            chance = 2 + (pops.free.total / 2_000_000)
        default:
            chance = 7 + (pops.free.total / 10_000_000)
        }

        guard random.roll(chance, 200 * (1 + self.factoriesUnderConstruction)) else {
            return nil
        }

        let priority: Resource?

        if  self.criticalShortages.isEmpty {
            priority = nil
        } else if
            let first: Resource = self.criticalShortages.first,
            self.criticalShortages.count == 1 {
            priority = first
        } else {
            priority = self.criticalShortages.randomElement(using: &random.generator)
        }

        let choices: [FactoryMetadata]

        if  let priority: Resource {
            choices = self.filter(factories: factories) { $0.output.contains(priority) }
        } else {
            choices = self.filter(factories: factories) { _ in true }
        }

        return choices.randomElement(using: &random.generator)
    }
}
extension PlanetGrid.Tile {
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
        let factor: Fraction = region.pops.occupation[.Miner]?.mineExpansionFactor else {
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
