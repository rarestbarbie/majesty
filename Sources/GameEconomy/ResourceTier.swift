import GameIDs
import OrderedCollections

@frozen public struct ResourceTier: Equatable, Hashable {
    public let segmented: OrderedDictionary<Resource, Int64>
    public let tradeable: OrderedDictionary<Resource, Int64>

    @inlinable public init(
        segmented: OrderedDictionary<Resource, Int64>,
        tradeable: OrderedDictionary<Resource, Int64>
    ) {
        self.segmented = segmented
        self.tradeable = tradeable
    }
}
