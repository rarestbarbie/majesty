import GameIDs
import OrderedCollections

/// Unlike ``SegmentedWeights``, the costs of `AggregateWeights.Tier` are only an estimate.
/// Therefore, we only track the total value of all resources across the tier.
extension AggregateWeights {
    @frozen public struct Tier {
        public let total: Double
    }
}
extension AggregateWeights.Tier {
    static var empty: Self { .init(total: 0) }
    static func compute(
        demands: ArraySlice<ResourceInput>,
        markets: borrowing WorldMarkets,
        currency: CurrencyID
    ) -> Self {
        .init(
            total: demands.reduce(0) {
                let units: Int64 = $1.unitsDemanded
                return $0 + Double.init(units) * markets.price(of: $1.id, in: currency)
            }
        )
    }
}
