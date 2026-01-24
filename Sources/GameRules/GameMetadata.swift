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

    public var tiles: Tiles
    public var pops: Pops
}
extension GameMetadata {
    init(
        symbols: GameSaveSymbols,
        objects: GameObjects,
        settings: Settings,
        legend: Legend.Description,
        ecology: OrderedDictionary<SymbolAssignment<EcologicalType>, EcologicalDescription>,
        geology: OrderedDictionary<SymbolAssignment<GeologicalType>, GeologicalDescription>,
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
            tiles: try .init(
                symbols: symbols,
                ecology: ecology,
                geology: geology
            ),
            pops: try .init(
                resources: objects.resources,
                symbols: symbols,
                layers: pops
            )
        )
    }
}
