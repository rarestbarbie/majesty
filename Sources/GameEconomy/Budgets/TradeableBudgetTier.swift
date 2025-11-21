import GameIDs
import OrderedCollections

/// Unlike ``InelasticBudgetTier``, the weights of `TradeableBudgetTier` are only an estimate.
/// Therefore, we only track the total weight of all resources across the tier.
@frozen public struct TradeableBudgetTier {
    public let total: Double
}
extension TradeableBudgetTier {
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
