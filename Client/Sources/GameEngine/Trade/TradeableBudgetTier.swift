import GameEconomy
import GameIDs
import OrderedCollections

/// Unlike ``InelasticBudgetTier``, the weights of `TradeableBudgetTier` are only an estimate.
/// Therefore, we only track the total weight of all resources across the tier.
struct TradeableBudgetTier {
    let total: Double
}
extension TradeableBudgetTier {
    static func compute(
        demands: OrderedDictionary<Resource, TradeableInput>,
        markets: borrowing Exchange,
        currency: Fiat
    ) -> Self {
        .init(
            total: demands.reduce(0) {
                let units: Int64 = $1.value.unitsDemanded
                return $0 + Double.init(units) * markets.price(of: $1.key, in: currency)
            }
        )
    }
}
