import GameEconomy
import GameIDs
import OrderedCollections

extension ResourceTier {
    init(
        metadata: OrderedDictionary<Resource, ResourceMetadata>,
        quantity: [Quantity<Resource>],
    ) {
        let x: (
            segmented: [(Resource, Int64)],
            tradeable: [(Resource, Int64)],
        ) = quantity.reduce(into: ([], [])) {
            if case true? = metadata[$1.unit]?.local {
                $0.segmented.append(($1.unit, $1.amount))
            } else {
                $0.tradeable.append(($1.unit, $1.amount))
            }
        }

        self.init(segmented: x.segmented, tradeable: x.tradeable)
    }
}
