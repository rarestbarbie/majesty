import GameEngine

public final class TerrainMetadata: Identifiable {
    public let id: TerrainType
    public let name: String
    public let color: Color

    init(id: TerrainType, name: String, color: Color) {
        self.id = id
        self.name = name
        self.color = color
    }
}
extension TerrainMetadata {
    var hash: Int {
        var hasher: Hasher = .init()
        // ID already hashed by dictionary key
        self.name.hash(into: &hasher)
        self.color.hash(into: &hasher)
        return hasher.finalize()
    }
}
