import GameEconomy

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
        map: borrowing GameMap,
    ) {
        let (l, e, x): (ResourceInputs, ResourceInputs, ResourceInputs) = tiers
        self.l.tradeable = .compute(
            demands: l.tradeable,
            markets: map.exchange,
            currency: currency,
        )
        self.e.tradeable = .compute(
            demands: e.tradeable,
            markets: map.exchange,
            currency: currency,
        )
        self.x.tradeable = .compute(
            demands: x.tradeable,
            markets: map.exchange,
            currency: currency,
        )

        self.l.inelastic = .compute(
            demands: l.inelastic,
            markets: map.localMarkets,
            location: location,
        )
        self.e.inelastic = .compute(
            demands: e.inelastic,
            markets: map.localMarkets,
            location: location,
        )
        self.x.inelastic = .compute(
            demands: x.inelastic,
            markets: map.localMarkets,
            location: location,
        )
    }
}
