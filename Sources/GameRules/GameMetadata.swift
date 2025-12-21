import GameIDs
import OrderedCollections

@frozen public struct GameMetadata: Sendable {
    public let settings: Settings
    public let legend: Legend

    public let resources: Resources
    public let buildings: OrderedDictionary<BuildingType, BuildingMetadata>
    public let factories: OrderedDictionary<FactoryType, FactoryMetadata>
    public let mines: OrderedDictionary<MineType, MineMetadata>
    public let technologies: OrderedDictionary<Technology, TechnologyMetadata>
    public let geology: OrderedDictionary<GeologicalType, GeologicalMetadata>
    public let terrains: OrderedDictionary<TerrainType, TerrainMetadata>

    public var pops: Pops
}
extension GameMetadata {
    init(
        symbols: GameSaveSymbols,
        objects: GameObjects,
        settings: Settings,
        legend: Legend.Description,
        pops: [PopAttributesDescription],
    ) throws {
        self.init(
            settings: settings,
            legend: .init(
                occupation: try legend.occupation.map(keys: symbols.occupations),
                gender: try legend.gender.map(keys: symbols.genders)
            ),
            resources: .init(
                fallback: .init(
                    identity: .init(code: .init(rawValue: -1), symbol: "_Unknown"),
                    color: 0xFFFFFF,
                    emoji: "?",
                    local: false,
                    critical: false,
                    storable: false,
                    hours: nil
                ),
                local: objects.resources.values.filter(\.local),
                table: objects.resources
            ),
            buildings: objects.buildings,
            factories: objects.factories,
            mines: objects.mines,
            technologies: objects.technologies,
            geology: objects.geology,
            terrains: objects.terrains,
            pops: try .init(
                resources: objects.resources,
                symbols: symbols,
                layers: pops
            )
        )
    }
}
extension GameMetadata {
    /// Compute a slow hash of the game rules, used for checking mod compatibility.
    public var hash: Int {
        var hasher: Hasher = .init()

        // TODO: hash settings, pops

        for value: ResourceMetadata in self.resources.all {
            value.hash.hash(into: &hasher)
        }
        for value: BuildingMetadata in self.buildings.values {
            value.hash.hash(into: &hasher)
        }
        for value: FactoryMetadata in self.factories.values {
            value.hash.hash(into: &hasher)
        }
        for value: MineMetadata in self.mines.values {
            value.hash.hash(into: &hasher)
        }
        for value: TechnologyMetadata in self.technologies.values {
            value.hash.hash(into: &hasher)
        }
        for value: GeologicalMetadata in self.geology.values {
            value.hash.hash(into: &hasher)
        }
        for value: TerrainMetadata in self.terrains.values {
            value.hash.hash(into: &hasher)
        }

        return hasher.finalize()
    }
}
