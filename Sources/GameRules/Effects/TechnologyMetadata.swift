import GameIDs

public final class TechnologyMetadata: GameMetadata {
    public typealias ID = Technology
    public let identity: SymbolAssignment<Technology>
    public let starter: Bool
    public let effects: [Effect]
    public let summary: String

    init(
        identity: SymbolAssignment<Technology>,
        starter: Bool,
        effects: [Effect],
        summary: String
    ) throws {
        self.identity = identity
        self.starter = starter
        self.effects = effects
        self.summary = summary
    }
}
extension TechnologyMetadata {
    var hash: Int {
        var hasher: Hasher = .init()

        self.identity.hash(into: &hasher)
        self.starter.hash(into: &hasher)
        self.effects.hash(into: &hasher)
        self.summary.hash(into: &hasher)

        return hasher.finalize()
    }
}
