import GameIDs
import OrderedCollections

/// Unlike ``PrecomputedBudgetTier``, the weights of `AggregateBudgetTier` are only an estimate.
/// Therefore, we only track the total weight of all resources across the tier.
@frozen public struct AggregateBudgetTier {
    public let total: Double
}
extension AggregateBudgetTier {
    public static func compute(
        demands: OrderedDictionary<Resource, ResourceInput>,
        markets: borrowing BlocMarkets,
        currency: CurrencyID
    ) -> Self {
        .init(
            total: demands.reduce(0) {
                let units: Int64 = $1.value.unitsDemanded
                return $0 + Double.init(units) * markets.price(of: $1.key, in: currency)
            }
        )
    }
}
