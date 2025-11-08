import GameEconomy
import GameIDs

public final class MineMetadata: Identifiable, Sendable {
    public let name: String
    public let base: ResourceTier
    public let miner: PopType
    public let decay: Bool
    public let geology: [GeologicalType: Int64]
    public let initialSize: Int64

    init(
        name: String,
        base: ResourceTier,
        miner: PopType,
        decay: Bool,
        geology: [GeologicalType: Int64],
        initialSize: Int64
    ) {
        self.name = name
        self.base = base
        self.miner = miner
        self.decay = decay
        self.geology = geology
        self.initialSize = initialSize
    }
}
extension MineMetadata {
    var hash: Int {
        var hasher: Hasher = .init()

        self.name.hash(into: &hasher)
        self.base.hash(into: &hasher)
        self.miner.hash(into: &hasher)
        self.decay.hash(into: &hasher)
        self.geology.hash(into: &hasher)
        self.initialSize.hash(into: &hasher)

        return hasher.finalize()
    }
}
