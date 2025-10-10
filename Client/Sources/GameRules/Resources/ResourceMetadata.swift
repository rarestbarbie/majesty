import Color

public final class ResourceMetadata: Identifiable {
    public let name: String

    public let color: Color
    public let emoji: Character
    public let local: Bool
    public let hours: Int64

    init(name: String, color: Color, emoji: Character, local: Bool, hours: Int64) {
        self.name = name
        self.color = color
        self.emoji = emoji
        self.local = local
        self.hours = hours
    }
}
extension ResourceMetadata {
    var hash: Int {
        var hasher: Hasher = .init()

        self.name.hash(into: &hasher)
        self.color.hash(into: &hasher)
        self.emoji.hash(into: &hasher)
        self.local.hash(into: &hasher)
        self.hours.hash(into: &hasher)

        return hasher.finalize()
    }
}
