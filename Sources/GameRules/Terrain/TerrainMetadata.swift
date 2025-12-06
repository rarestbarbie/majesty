import Color
import GameIDs

public final class TerrainMetadata: GameObjectMetadata {
    public typealias ID = TerrainType
    public let identity: SymbolAssignment<TerrainType>
    public let color: Color

    init(identity: SymbolAssignment<TerrainType>, color: Color) {
        self.identity = identity
        self.color = color
    }
}
extension TerrainMetadata {
    var hash: Int {
        var hasher: Hasher = .init()
        self.identity.hash(into: &hasher)
        self.color.hash(into: &hasher)
        return hasher.finalize()
    }
}
