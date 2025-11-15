import GameEconomy
import GameIDs

public final class MineMetadata: GameMetadata {
    public typealias ID = MineType
    public let identity: SymbolAssignment<MineType>
    public let base: ResourceTier
    public let miner: PopType
    public let decay: Bool
    public let scale: Int64
    public let spawn: [GeologicalType: SpawnWeight]

    init(
        identity: SymbolAssignment<MineType>,
        base: ResourceTier,
        miner: PopType,
        decay: Bool,
        scale: Int64,
        spawn: [GeologicalType: SpawnWeight],
    ) {
        guard scale > 0 else {
            fatalError("Mine scale must be positive!!!")
        }

        self.identity = identity
        self.base = base
        self.miner = miner
        self.decay = decay
        self.scale = scale
        self.spawn = spawn
    }
}
extension MineMetadata {
    var hash: Int {
        var hasher: Hasher = .init()

        self.identity.hash(into: &hasher)
        self.base.hash(into: &hasher)
        self.miner.hash(into: &hasher)
        self.decay.hash(into: &hasher)
        self.scale.hash(into: &hasher)

        for (key, value): (GeologicalType, SpawnWeight) in self.spawn.sorted(by: { $0.key < $1.key }) {
            key.hash(into: &hasher)
            value.hash(into: &hasher)
        }

        return hasher.finalize()
    }
}
