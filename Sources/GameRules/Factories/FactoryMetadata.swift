import GameEconomy
import GameIDs

public final class FactoryMetadata: GameObjectMetadata {
    public typealias ID = FactoryType
    public let identity: SymbolAssignment<FactoryType>
    public let materials: ResourceTier
    public let corporate: ResourceTier
    public let expansion: ResourceTier
    public let output: ResourceTier
    public let workers: Quantity<PopOccupation>
    public let clerks: Quantity<PopOccupation>

    public let sharesInitial: Int64
    public let sharesPerLevel: Int64

    public let terrainAllowed: Set<EcologicalType>

    init(
        identity: SymbolAssignment<FactoryType>,
        materials: ResourceTier,
        corporate: ResourceTier,
        expansion: ResourceTier,
        output: ResourceTier,
        workers divisions: [Quantity<PopOccupation>],
        sharesInitial: Int64,
        sharesPerLevel: Int64,
        terrainAllowed: Set<EcologicalType>
    ) throws {
        self.identity = identity

        self.materials = materials
        self.corporate = corporate
        self.expansion = expansion
        self.output = output

        let workers: [Quantity<PopOccupation>] = divisions.filter { $0.unit.stratum <= .Worker }
        let clerks: [Quantity<PopOccupation>] = divisions.filter { $0.unit.stratum > .Worker }

        guard workers.count == 1 else {
            throw FactoryMetadataError.workers(workers.map { $0.unit })
        }
        guard clerks.count == 1 else {
            throw FactoryMetadataError.clerks(clerks.map { $0.unit })
        }

        self.workers = workers[0]
        self.clerks = clerks[0]

        self.sharesInitial = sharesInitial
        self.sharesPerLevel = sharesPerLevel

        self.terrainAllowed = terrainAllowed
    }
}
extension FactoryMetadata {
    var hash: Int {
        var hasher: Hasher = .init()

        self.identity.hash(into: &hasher)
        self.materials.hash(into: &hasher)
        self.corporate.hash(into: &hasher)
        self.expansion.hash(into: &hasher)
        self.output.hash(into: &hasher)

        self.workers.hash(into: &hasher)
        self.clerks.hash(into: &hasher)
        self.sharesInitial.hash(into: &hasher)
        self.sharesPerLevel.hash(into: &hasher)
        self.terrainAllowed.hash(into: &hasher)

        return hasher.finalize()
    }
}
