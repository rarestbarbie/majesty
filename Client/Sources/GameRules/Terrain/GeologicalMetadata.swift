import Color
import GameEconomy
import OrderedCollections

public final class GeologicalMetadata: Identifiable {
    public let id: GeologicalType
    public let name: String
    public let base: OrderedDictionary<Resource, Int64>
    public let bonus: [Resource: Bonuses]
    public let color: Color

    init(
        id: GeologicalType,
        name: String,
        base: OrderedDictionary<Resource, Int64>,
        bonus: [Resource: Bonuses],
        color: Color
    ) {
        self.id = id
        self.name = name
        self.base = base
        self.bonus = bonus
        self.color = color
    }
}
extension GeologicalMetadata {
    var hash: Int {
        var hasher: Hasher = .init()
        // ID already hashed by dictionary key
        self.name.hash(into: &hasher)
        self.base.hash(into: &hasher)
        self.bonus.hash(into: &hasher)
        self.color.hash(into: &hasher)
        return hasher.finalize()
    }
}
