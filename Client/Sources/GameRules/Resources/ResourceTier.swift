import GameEconomy
import OrderedCollections

@frozen public struct ResourceTier: Equatable, Hashable {
    public let inelastic: OrderedDictionary<Resource, Int64>
    public let tradeable: OrderedDictionary<Resource, Int64>
}
extension ResourceTier {
    init(
        metadata: OrderedDictionary<Resource, ResourceMetadata>,
        quantity: [Quantity<Resource>],
    ) {
        var inelastic: OrderedDictionary<Resource, Int64> = [:]
        var tradeable: OrderedDictionary<Resource, Int64> = [:]
        for resource: Quantity<Resource> in quantity {
            if case true? = metadata[resource.unit]?.local {
                inelastic[resource.unit] = resource.amount
            } else {
                tradeable[resource.unit] = resource.amount
            }
        }

        self.init(inelastic: inelastic, tradeable: tradeable)
    }
}
