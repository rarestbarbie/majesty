import OrderedCollections

@frozen public struct ResourceTier: Equatable, Hashable {
    public let inelastic: OrderedDictionary<Resource, Int64>
    public let tradeable: OrderedDictionary<Resource, Int64>

    @inlinable public init(
        inelastic: OrderedDictionary<Resource, Int64>,
        tradeable: OrderedDictionary<Resource, Int64>
    ) {
        self.inelastic = inelastic
        self.tradeable = tradeable
    }
}
