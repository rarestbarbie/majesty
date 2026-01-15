import Color
import GameIDs
import OrderedCollections

@frozen public struct GeologicalAttributes: Symbolizable, Equatable, Hashable {
    public typealias ID = GeologicalType
    public let identity: SymbolAssignment<GeologicalType>
    public let title: String
    @usableFromInline let base: OrderedDictionary<Resource, Int64>
    @usableFromInline let bonus: [Resource: Bonuses]
    @usableFromInline let color: Color

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
