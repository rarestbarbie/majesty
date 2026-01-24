import GameIDs

public final class TechnologyMetadata: GameObjectMetadata {
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
    ) {
        self.identity = identity
        self.starter = starter
        self.effects = effects
        self.summary = summary
    }
}
