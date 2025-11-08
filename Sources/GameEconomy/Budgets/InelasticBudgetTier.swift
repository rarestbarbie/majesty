import Fraction
import GameIDs
import OrderedCollections

@frozen public struct InelasticBudgetTier {
    public let x: [Weight]
}
extension InelasticBudgetTier {
    public static func compute(
        demands: OrderedDictionary<Resource, ResourceInput<Never>>,
        markets: LocalMarkets,
        location: Address,
    ) -> Self {
        return .init(
            x: demands.map {
                .init(
                    id: $0,
                    unitsToPurchase: $1.needed($1.unitsDemanded),
                    units: $1.unitsDemanded,
                    value: $1.unitsDemanded >< markets[location, $0].yesterday.price.value
                )
            }
        )
    }

    public var total: Int64 {
        self.x.reduce(into: 0) { $0 += $1.value }
    }
}
