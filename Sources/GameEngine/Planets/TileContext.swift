import Fraction
import GameEconomy
import GameRules
import GameIDs
import GameState
import GameTerrain
import HexGrids
import OrderedCollections
import Random

struct TileContext: RuntimeContext {
    let type: TileMetadata
    var state: Tile

    private(set) var properties: RegionalProperties?
    private(set) var authority: DiplomaticAuthority?
    private var stats: Tile.Stats

    // Computed statistics
    private(set) var buildingsAlreadyPresent: Set<BuildingType>
    private(set) var buildings: [BuildingID]

    private(set) var factoriesUnderConstruction: Int64
    private(set) var factoriesAlreadyPresent: Set<FactoryType>
    private(set) var factories: [FactoryID]

    private(set) var pops: (enslaved: [PopID], free: [PopID])

    private(set) var minesAlreadyPresent: [MineType: (size: Int64, yieldRank: Int?)]
    private(set) var mines: [MineID]
    private var criticalShortages: [Resource]

    init(type: TileMetadata, state: Tile) {
        self.type = type
        self.state = state

        self.properties = nil
        self.authority = nil
        self.stats = .init()

        self.buildingsAlreadyPresent = []
        self.buildings = []

        self.factoriesUnderConstruction = 0
        self.factoriesAlreadyPresent = []
        self.factories = []

        self.pops = (enslaved: [], free: [])

        self.minesAlreadyPresent = [:]
        self.mines = []

        self.criticalShortages = []
    }
}
extension TileContext {
    var id: Address { self.state.id }

    var snapshot: TileSnapshot {
        var history: [Tile.Aggregate] = [];
        history.reserveCapacity(self.state.history.count + 1)
        history += self.state.history
        history.append(self.today)

        return .init(
            metadata: self.type,
            id: self.id,
            type: self.state.type,
            name: self.state.name,
            history: history,
            country: self.authority,
            y: self.state.y,
            z: .init(stats: self.stats, state: self.state.z)
        )
    }

    var terrain: Terrain {
        .init(
            id: self.state.id.tile,
            name: self.state.name,
            ecology: self.type.ecology.symbol,
            geology: self.type.geology.symbol
        )
    }
}
extension TileContext {
    mutating func startIndexCount() {
        self.buildingsAlreadyPresent.removeAll(keepingCapacity: true)
        self.buildings.removeAll(keepingCapacity: true)

        self.factoriesUnderConstruction = 0
        self.factoriesAlreadyPresent.removeAll(keepingCapacity: true)
        self.factories.removeAll(keepingCapacity: true)

        // use the previous day’s counts to allocate capacity
        let count: (enslaved: Int, free: Int) = (self.pops.enslaved.count, self.pops.free.count)
        self.pops.enslaved = []
        self.pops.enslaved.reserveCapacity(count.enslaved)
        self.pops.free = []
        self.pops.free.reserveCapacity(count.free)

        self.minesAlreadyPresent.removeAll(keepingCapacity: true)
        self.mines.removeAll(keepingCapacity: true)

        self.stats.startIndexCount()
    }

    mutating func addResidentCount(_ pop: Pop, _ stats: Pop.Stats) -> RegionalAuthority? {
        if  pop.occupation.stratum <= .Ward {
            self.pops.enslaved.append(pop.id)
        } else {
            self.pops.free.append(pop.id)
        }

        self.stats.pops.addResidentCount(pop, stats)
        // this should not return the ``RegionalProperties``, that has not been published yet
        return self.authority?[self.id]
    }
    mutating func addResidentCount(_ building: Building) -> RegionalAuthority? {
        self.buildings.append(building.id)
        self.buildingsAlreadyPresent.insert(building.type)
        return self.authority?[self.id]
    }
    mutating func addResidentCount(_ factory: Factory) -> RegionalAuthority? {
        self.factories.append(factory.id)
        self.factoriesAlreadyPresent.insert(factory.type)

        if factory.size.level == 0 {
            self.factoriesUnderConstruction += 1
        }

        return self.authority?[self.id]
    }
    mutating func addResidentCount(_ mine: Mine) {
        self.mines.append(mine.id)
        self.minesAlreadyPresent[mine.type] = (mine.z.size, mine.z.yieldRank)
    }

    mutating func update(authority: DiplomaticAuthority) {
        self.authority = authority
    }
    mutating func update(economy: EconomicStats) {
        self.stats.economy = economy
    }

    mutating func afterIndexCount(world: borrowing GameWorld) {
        guard let authority: DiplomaticAuthority = self.authority else {
            self.properties = nil
            return
        }

        self.properties = .init(
            id: self.id,
            name: self.state.name ?? "",
            country: authority,
            stats: self.stats,
            state: self.state.z // when this is called, always the same as `y`
        )

        self.criticalShortages = authority.criticalResources.filter {
            if  let localMarket: LocalMarket = world.localMarkets[$0 / self.id],
                    localMarket.today.supply == 0,
                    localMarket.today.demand > 0 {
                return true
            } else {
                return false
            }
        }
    }
}
extension TileContext {
    private static var history: Int { 5 * 365 }
    private var today: Tile.Aggregate {
        .init(
            gdp: self.stats.economy.gdp,
        )
    }

    mutating func advance(turn _: inout Turn) throws {
        self.state.y = .init(stats: self.stats, state: self.state.z)

        guard case _? = self.properties else {
            self.state.history = []
            return
        }

        if  self.state.history.count >= Self.history {
            self.state.history.removeFirst()
        }

        self.state.history.append(self.today)
    }
}
extension TileContext {
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
extension TileContext {
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
                $0.terrainAllowed.contains(self.type.ecology.id) {
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
extension TileContext {
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
                tile: self.type.geology.id,
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
                tile: self.type.geology.id
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
