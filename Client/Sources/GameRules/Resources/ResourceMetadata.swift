import Color

public final class ResourceMetadata: Identifiable {
    public let name: String

    public let color: Color
    public let emoji: Character
    public let local: Bool

    init(name: String, color: Color, emoji: Character, local: Bool) {
        self.name = name
        self.color = color
        self.emoji = emoji
        self.local = local
    }
}
extension ResourceMetadata {
    var hash: Int {
        var hasher: Hasher = .init()

        self.name.hash(into: &hasher)
        self.color.hash(into: &hasher)
        self.emoji.hash(into: &hasher)
        self.local.hash(into: &hasher)

        return hasher.finalize()
    }
}
