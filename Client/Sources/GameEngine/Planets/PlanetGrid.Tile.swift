import GameEconomy
import GameRules
import GameIDs
import GameTerrain
import HexGrids
import OrderedCollections
import Random

extension PopulationStratum {
    struct Fields {
        var mil: Double
        var con: Double
    }
}
extension PopulationStratum.Fields {
    static var zero: Self {
        .init(
            mil: 0,
            con: 0
        )
    }
}

@dynamicMemberLookup
struct PopulationStratum {
    var all: [PopID]
    var total: Int64
    var cultures: [String: Int64]
    var weighted: Fields
}
extension PopulationStratum {
    init() {
        self.init(all: [], total: 0, cultures: [:], weighted: .zero)
    }
}
extension PopulationStratum {
    subscript<Float>(dynamicMember keyPath: KeyPath<Fields, Float>) -> (Float, of: Float) where Float: BinaryFloatingPoint {
        let population: Float = .init(self.total)
        if  population < 0 {
            return (0, 0)
        } else {
            return (self.weighted[keyPath: keyPath] / population, population)
        }
    }
}
extension PopulationStratum {
    mutating func startIndexCount() {
        self.all.removeAll(keepingCapacity: true)
        self.total = 0
        self.cultures.removeAll(keepingCapacity: true)
        self.weighted = .zero
    }

    mutating func addResidentCount(_ pop: Pop) {
        let weight: Double = .init(pop.today.size)
        self.all.append(pop.id)
        self.total += pop.today.size
        self.cultures[pop.nat, default: 0] += pop.today.size
        self.weighted.mil += pop.today.mil * weight
        self.weighted.con += pop.today.con * weight
    }
}

struct PopulationStats {
    var type: [PopType: Int64]
    var free: PopulationStratum
    var enslaved: PopulationStratum
}
extension PopulationStats {
    init() {
        self.init(type: [:], free: .init(), enslaved: .init())
    }
}
extension PopulationStats {
    var total: Int64 { self.free.total + self.enslaved.total }
}
extension PopulationStats {
    mutating func startIndexCount() {
        self.type.removeAll(keepingCapacity: true)
        self.free.startIndexCount()
        self.enslaved.startIndexCount()
    }

    mutating func addResidentCount(_ pop: Pop) {
        self.type[pop.type, default: 0] += pop.today.size

        if pop.type.stratum <= .Ward {
            self.enslaved.addResidentCount(pop)
        } else {
            self.free.addResidentCount(pop)
        }
    }
}

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
}
