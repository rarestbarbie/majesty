import Color

public final class ResourceMetadata: Identifiable {
    public let name: String

    public let color: Color
    public let emoji: Character

    init(name: String, color: Color, emoji: Character) {
        self.name = name
        self.color = color
        self.emoji = emoji
    }
}
extension ResourceMetadata {
    var hash: Int {
        var hasher: Hasher = .init()

        self.name.hash(into: &hasher)
        self.color.hash(into: &hasher)
        self.emoji.hash(into: &hasher)

        return hasher.finalize()
    }
}
