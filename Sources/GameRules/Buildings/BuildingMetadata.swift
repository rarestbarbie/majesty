import GameEconomy
import GameIDs

public final class BuildingMetadata: GameMetadata {
    public typealias ID = BuildingType
    public let identity: SymbolAssignment<BuildingType>
    public let maintenance: ResourceTier
    public let development: ResourceTier
    public let output: ResourceTier

    public let sharesInitial: Int64
    public let sharesPerLevel: Int64

    public let terrainAllowed: Set<TerrainType>

    init(
        identity: SymbolAssignment<BuildingType>,
        maintenance: ResourceTier,
        development: ResourceTier,
        output: ResourceTier,
        sharesInitial: Int64,
        sharesPerLevel: Int64,
        terrainAllowed: Set<TerrainType>
    ) throws {
        self.identity = identity

        self.maintenance = maintenance
        self.development = development
        self.output = output

        self.sharesInitial = sharesInitial
        self.sharesPerLevel = sharesPerLevel
        self.terrainAllowed = terrainAllowed
    }
}
extension BuildingMetadata {
    var hash: Int {
        var hasher: Hasher = .init()

        self.identity.hash(into: &hasher)
        self.maintenance.hash(into: &hasher)
        self.development.hash(into: &hasher)
        self.output.hash(into: &hasher)
        self.sharesInitial.hash(into: &hasher)
        self.sharesPerLevel.hash(into: &hasher)
        self.terrainAllowed.hash(into: &hasher)

        return hasher.finalize()
    }
}
