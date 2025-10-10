import GameEconomy
import GameIDs
import OrderedCollections

struct InelasticBudgetTier {
    let x: [Weight]
}
extension InelasticBudgetTier {
    static func compute(
        demands: OrderedDictionary<Resource, InelasticInput>,
        markets: LocalMarkets,
        location: Address,
    ) -> Self {
        return .init(
            x: demands.map {
                .init(
                    id: $0,
                    unitsToPurchase: $1.needed($1.unitsDemanded),
                    units: $1.unitsDemanded,
                    value: $1.unitsDemanded * markets[location, $0].yesterday.price
                )
            }
        )
    }

    var total: Int64 {
        self.x.reduce(into: 0) { $0 += $1.value }
    }
}
