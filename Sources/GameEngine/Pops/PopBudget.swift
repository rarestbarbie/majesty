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
        weights: __shared (
            segmented: SegmentedWeights<ElasticDemand>,
            tradeable: AggregateWeights
        ),
        balance: Int64,
        stockpileMaxDays: Int64,
        d: (l: Int64, e: Int64, x: Int64)
    ) {
        self.l = .init()
        self.e = .init()
        self.x = .init()
        self.dividend = 0
        self.buybacks = 0

        let segmentedCostPerDay: (l: Int64, e: Int64, x: Int64) = (
            l: weights.segmented.l.total,
            e: weights.segmented.e.total,
            x: weights.segmented.x.total,
        )
        let tradeableCostPerDay: (l: Int64, e: Int64, x: Int64) = (
            l: Int64.init(weights.tradeable.l.total.rounded(.up)),
            e: Int64.init(weights.tradeable.e.total.rounded(.up)),
            x: Int64.init(weights.tradeable.x.total.rounded(.up)),
        )
        let totalCostPerDay: (l: Int64, e: Int64) = (
            l: tradeableCostPerDay.l + segmentedCostPerDay.l,
            e: tradeableCostPerDay.e + segmentedCostPerDay.e,
        )

        /// These are the minimum theoretical balances the pop would need to purchase 100% of
        /// its needs in that tier on any particular day.
        self.min = (
            l: totalCostPerDay.l * d.l,
            e: totalCostPerDay.e * d.e,
        )

        self.l.distributeAsConsumer(
            funds: balance / d.l,
            segmented: segmentedCostPerDay.l * stockpileMaxDays,
            tradeable: tradeableCostPerDay.l * stockpileMaxDays,
        )

        self.e.distributeAsConsumer(
            funds: (balance - min.l) / d.e,
            segmented: segmentedCostPerDay.e * stockpileMaxDays,
            tradeable: tradeableCostPerDay.e * stockpileMaxDays,
        )

        self.x.distributeAsConsumer(
            funds: (balance - min.l - min.e) / d.x,
            segmented: segmentedCostPerDay.x * stockpileMaxDays,
            tradeable: tradeableCostPerDay.x * stockpileMaxDays,
        )
    }
}
