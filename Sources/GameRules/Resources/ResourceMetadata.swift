import Color
import GameIDs

public final class ResourceMetadata: GameMetadata {
    public typealias ID = Resource
    public let identity: SymbolAssignment<Resource>
    public let color: Color
    public let emoji: Character
    public let local: Bool
    public let storable: Bool
    public let hours: Int64?

    init(
        identity: SymbolAssignment<Resource>,
        color: Color,
        emoji: Character,
        local: Bool,
        storable: Bool,
        hours: Int64?
    ) {
        self.identity = identity
        self.color = color
        self.emoji = emoji
        self.local = local
        self.storable = storable
        self.hours = hours
    }
}
extension ResourceMetadata {
    var hash: Int {
        var hasher: Hasher = .init()

        self.identity.hash(into: &hasher)
        self.color.hash(into: &hasher)
        self.emoji.hash(into: &hasher)
        self.local.hash(into: &hasher)
        self.storable.hash(into: &hasher)
        self.hours.hash(into: &hasher)

        return hasher.finalize()
    }
}
