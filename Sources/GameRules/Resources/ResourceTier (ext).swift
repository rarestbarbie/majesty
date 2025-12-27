import GameEconomy
import GameIDs
import OrderedCollections

extension ResourceTier {
    init(
        metadata: OrderedDictionary<Resource, ResourceMetadata>,
        quantity: [Quantity<Resource>],
    ) {
        let x: (
            segmented: [Quantity<Resource>],
            tradeable: [Quantity<Resource>],
        ) = quantity.reduce(into: ([], [])) {
            if case true? = metadata[$1.unit]?.local {
                $0.segmented.append($1)
            } else {
                $0.tradeable.append($1)
            }
        }

        self.init(segmented: x.segmented, tradeable: x.tradeable)
    }
}
