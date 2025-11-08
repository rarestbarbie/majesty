import GameEconomy
import GameIDs
import OrderedCollections

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
