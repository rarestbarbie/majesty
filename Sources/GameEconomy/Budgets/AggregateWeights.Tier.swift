import GameIDs
import OrderedCollections

/// Unlike ``SegmentedWeights``, the costs of `AggregateWeights.Tier` are only an estimate.
/// Therefore, we only track the total value of all resources across the tier.
extension AggregateWeights {
    @frozen public struct Tier {
        @usableFromInline let total: Demand.Column
    }
}
extension AggregateWeights.Tier where Demand.Column: AggregateDemandColumn {
    static var empty: Self { .init(total: .zero) }

    static func compute(
        demands: ArraySlice<ResourceInput>,
        markets: borrowing WorldMarkets,
        currency: CurrencyID
    ) -> Self {
        .init(total: .aggregate(demands: demands, markets: markets, currency: currency))
    }
}
extension AggregateWeights<ElasticDemand>.Tier {
    @inlinable public var weight: Demand.Weight { self.total.weight }
}
