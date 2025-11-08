import GameEconomy

struct PopBudget {
    /// These are the minimum theoretical balances the pop would need to purchase 100% of
    /// its needs in that tier on any particular day.
    let min: (l: Int64, e: Int64)

    var l: ResourceBudgetTier
    var e: ResourceBudgetTier
    var x: ResourceBudgetTier
    var dividend: Int64
    var buybacks: Int64
}
extension PopBudget {
    init(
        weights: __shared ResourceInputWeights,
        balance: Int64,
        stockpileMaxDays: Int64,
        d: (l: Int64, e: Int64, x: Int64)
    ) {
        self.l = .init()
        self.e = .init()
        self.x = .init()
        self.dividend = 0
        self.buybacks = 0

        let inelasticCostPerDay: (l: Int64, e: Int64, x: Int64) = (
            l: weights.l.inelastic.total,
            e: weights.e.inelastic.total,
            x: weights.x.inelastic.total,
        )
        let tradeableCostPerDay: (l: Int64, e: Int64, x: Int64) = (
            l: Int64.init(weights.l.tradeable.total.rounded(.up)),
            e: Int64.init(weights.e.tradeable.total.rounded(.up)),
            x: Int64.init(weights.x.tradeable.total.rounded(.up)),
        )
        let totalCostPerDay: (l: Int64, e: Int64) = (
            l: tradeableCostPerDay.l + inelasticCostPerDay.l,
            e: tradeableCostPerDay.e + inelasticCostPerDay.e,
        )

        /// These are the minimum theoretical balances the pop would need to purchase 100% of
        /// its needs in that tier on any particular day.
        self.min = (
            l: totalCostPerDay.l * d.l,
            e: totalCostPerDay.e * d.e,
        )

        self.l.distribute(
            funds: balance / d.l,
            inelastic: inelasticCostPerDay.l * stockpileMaxDays,
            tradeable: tradeableCostPerDay.l * stockpileMaxDays,
        )

        self.e.distribute(
            funds: (balance - min.l) / d.e,
            inelastic: inelasticCostPerDay.e * stockpileMaxDays,
            tradeable: tradeableCostPerDay.e * stockpileMaxDays,
        )

        self.x.distribute(
            funds: (balance - min.l - min.e) / d.x,
            inelastic: inelasticCostPerDay.x * stockpileMaxDays,
            tradeable: tradeableCostPerDay.x * stockpileMaxDays,
        )
    }
}
