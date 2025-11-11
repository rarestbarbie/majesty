import GameEconomy
import GameIDs

struct ResourceInputWeights {
    let l: (tradeable: TradeableBudgetTier, inelastic: InelasticBudgetTier)
    let e: (tradeable: TradeableBudgetTier, inelastic: InelasticBudgetTier)
    let x: (tradeable: TradeableBudgetTier, inelastic: InelasticBudgetTier)
}
extension ResourceInputWeights {
    init(
        tiers: __shared (ResourceInputs, ResourceInputs, ResourceInputs),
        location: Address,
        currency: Fiat,
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

        self.l.inelastic = .compute(
            demands: l.inelastic,
            markets: turn.localMarkets,
            location: location,
        )
        self.e.inelastic = .compute(
            demands: e.inelastic,
            markets: turn.localMarkets,
            location: location,
        )
        self.x.inelastic = .compute(
            demands: x.inelastic,
            markets: turn.localMarkets,
            location: location,
        )
    }
}
