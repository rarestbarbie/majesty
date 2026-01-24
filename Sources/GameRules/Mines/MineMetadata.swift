import GameEconomy
import GameIDs

public final class MineMetadata: GameObjectMetadata {
    public typealias ID = MineType
    public let identity: SymbolAssignment<MineType>
    public let base: ResourceTier
    public let miner: PopOccupation
    public let decay: Bool
    public let scale: Int64
    public let spawn: [GeologicalType: SpawnWeight]

    init(
        identity: SymbolAssignment<MineType>,
        base: ResourceTier,
        miner: PopOccupation,
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
