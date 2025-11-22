import Fraction
import GameIDs
import OrderedCollections

@frozen public struct SegmentedBudgetTier {
    public let x: [Weight]
}
extension SegmentedBudgetTier {
    public static func compute(
        demands: OrderedDictionary<Resource, ResourceInput>,
        markets: LocalMarkets,
        location: Address,
    ) -> Self {
        return .init(
            x: demands.map {
                .init(
                    id: $0,
                    unitsToPurchase: $1.needed($1.unitsDemanded),
                    units: $1.unitsDemanded,
                    value: $1.unitsDemanded >< markets[$0 / location].yesterday.ask.value
                )
            }
        )
    }

    public var total: Int64 {
        self.x.reduce(into: 0) { $0 += $1.value }
    }
}
