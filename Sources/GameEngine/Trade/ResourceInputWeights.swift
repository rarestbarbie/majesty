import GameEconomy
import GameIDs

struct ResourceInputWeights {
    let l: (tradeable: TradeableBudgetTier, segmented: InelasticBudgetTier)
    let e: (tradeable: TradeableBudgetTier, segmented: InelasticBudgetTier)
    let x: (tradeable: TradeableBudgetTier, segmented: InelasticBudgetTier)
}
extension ResourceInputWeights {
    init(
        tiers: __shared (ResourceInputs, ResourceInputs, ResourceInputs),
        location: Address,
        currency: CurrencyID,
        turn: borrowing Turn,
    ) {
        let (l, e, x): (ResourceInputs, ResourceInputs, ResourceInputs) = tiers
        self.l.tradeable = .compute(
            demands: l.tradeable,
            markets: turn.worldMarkets,
            currency: currency,
        )
        self.e.tradeable = .compute(
            demands: e.tradeable,
            markets: turn.worldMarkets,
            currency: currency,
        )
        self.x.tradeable = .compute(
            demands: x.tradeable,
            markets: turn.worldMarkets,
            currency: currency,
        )

        self.l.segmented = .compute(
            demands: l.segmented,
            markets: turn.localMarkets,
            location: location,
        )
        self.e.segmented = .compute(
            demands: e.segmented,
            markets: turn.localMarkets,
            location: location,
        )
        self.x.segmented = .compute(
            demands: x.segmented,
            markets: turn.localMarkets,
            location: location,
        )
    }
}
