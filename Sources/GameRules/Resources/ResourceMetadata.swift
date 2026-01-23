import Color
import GameIDs

public final class ResourceMetadata: GameObjectMetadata {
    public typealias ID = Resource
    public let identity: SymbolAssignment<Resource>
    public let color: Color
    public let emoji: Character
    public let local: Bool
    public let critical: Bool
    public let storable: Bool
    public let hours: Int64?

    init(
        identity: SymbolAssignment<Resource>,
        color: Color,
        emoji: Character,
        local: Bool,
        critical: Bool,
        storable: Bool,
        hours: Int64?
    ) {
        self.identity = identity
        self.color = color
        self.emoji = emoji
        self.local = local
        self.critical = critical
        self.storable = storable
        self.hours = hours

        if !self.local {
            if self.critical {
                fatalError("Resource '\(self.title)' has flag 'critical' but not local!")
            }
            if self.storable {
                fatalError("Resource '\(self.title)' has flag 'storable' but not local!")
            }
            if self.hours != nil {
                fatalError("Resource '\(self.title)' has field 'hours' but is not local!")
            }
        }
    }
}
