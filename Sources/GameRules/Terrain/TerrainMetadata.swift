import Color
import GameIDs

public final class TerrainMetadata: Identifiable {
    public let id: TerrainType
    public let symbol: Symbol
    public let color: Color

    init(id: TerrainType, symbol: Symbol, color: Color) {
        self.id = id
        self.symbol = symbol
        self.color = color
    }
}
extension TerrainMetadata {
    @inlinable public var name: String { self.symbol.name }
}
extension TerrainMetadata {
    var hash: Int {
        var hasher: Hasher = .init()
        // ID already hashed by dictionary key
        self.symbol.hash(into: &hasher)
        self.color.hash(into: &hasher)
        return hasher.finalize()
    }
}
