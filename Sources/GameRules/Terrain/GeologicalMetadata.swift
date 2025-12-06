import Color
import GameIDs
import OrderedCollections

public final class GeologicalMetadata: GameObjectMetadata {
    public typealias ID = GeologicalType
    public let identity: SymbolAssignment<GeologicalType>
    public let title: String
    public let base: OrderedDictionary<Resource, Int64>
    public let bonus: [Resource: Bonuses]
    public let color: Color

    init(
        identity: SymbolAssignment<GeologicalType>,
        title: String,
        base: OrderedDictionary<Resource, Int64>,
        bonus: [Resource: Bonuses],
        color: Color
    ) {
        self.identity = identity
        self.title = title
        self.base = base
        self.bonus = bonus
        self.color = color
    }
}
extension GeologicalMetadata {
    var hash: Int {
        var hasher: Hasher = .init()
        self.identity.hash(into: &hasher)
        self.title.hash(into: &hasher)
        self.base.hash(into: &hasher)
        self.bonus.hash(into: &hasher)
        self.color.hash(into: &hasher)
        return hasher.finalize()
    }
}
