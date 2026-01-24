import Color
import GameEconomy
import GameIDs

public final class BuildingMetadata: GameObjectMetadata {
    public typealias ID = BuildingType
    public let identity: SymbolAssignment<BuildingType>
    public let color: Color
    public let operations: ResourceTier
    public let maintenance: ResourceTier
    public let development: ResourceTier
    public let output: ResourceTier

    public let sharesInitial: Int64
    public let sharesPerLevel: Int64

    public let terrainAllowed: Set<EcologicalType>
    public let required: Bool

    init(
        identity: SymbolAssignment<BuildingType>,
        color: Color,
        operations: ResourceTier,
        maintenance: ResourceTier,
        development: ResourceTier,
        output: ResourceTier,
        sharesInitial: Int64,
        sharesPerLevel: Int64,
        terrainAllowed: Set<EcologicalType>,
        required: Bool
    ) {
        self.identity = identity
        self.color = color

        self.operations = operations
        self.maintenance = maintenance
        self.development = development
        self.output = output

        self.sharesInitial = sharesInitial
        self.sharesPerLevel = sharesPerLevel
        self.terrainAllowed = terrainAllowed
        self.required = required
    }
}
