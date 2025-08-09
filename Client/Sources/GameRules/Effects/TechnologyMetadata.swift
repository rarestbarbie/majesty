public final class TechnologyMetadata: Identifiable, Sendable {
    public let name: String
    public let starter: Bool
    public let effects: [Effect]
    public let summary: String

    init(
        name: String,
        starter: Bool,
        effects: [Effect],
        summary: String
    ) throws {
        self.name = name
        self.starter = starter
        self.effects = effects
        self.summary = summary
    }
}
extension TechnologyMetadata {
    var hash: Int {
        var hasher: Hasher = .init()

        self.name.hash(into: &hasher)
        self.starter.hash(into: &hasher)
        self.effects.hash(into: &hasher)
        self.summary.hash(into: &hasher)

        return hasher.finalize()
    }
}
