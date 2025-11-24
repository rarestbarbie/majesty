import GameEconomy

struct PopBudget {
    /// These are the minimum theoretical balances the pop would need to purchase 100% of
    /// its needs in that tier on any particular day.
    let min: (l: Int64, e: Int64)

    private(set) var l: ResourceBudgetTier
    private(set) var e: ResourceBudgetTier
    private(set) var x: ResourceBudgetTier
    private(set) var dividend: Int64
    private(set) var buybacks: Int64
}
extension PopBudget {
    static func slave(
        weights: __shared (
            segmented: SegmentedWeights<InelasticDemand>,
            tradeable: AggregateWeights
        ),
        balance: Int64,
        stockpileMaxDays: Int64,
        d: Int64,
    ) -> Self {
        let segmentedCostPerDay: (l: Int64, e: Int64, x: Int64) = weights.segmented.total
        let tradeableCostPerDay: (l: Int64, e: Int64, x: Int64) = weights.tradeable.total
        let totalCostPerDay: Int64 = tradeableCostPerDay.l + segmentedCostPerDay.l

        var budget: Self = .init(
            min: (l: totalCostPerDay * d, e: 0),
            l: .init(),
            e: .init(),
            x: .init(),
            dividend: 0,
            buybacks: 0
        )

        budget.dividend = max(0, (balance - budget.min.l) / 3650)
        budget.buybacks = max(0, (balance - budget.min.l - budget.dividend) / 365)

        budget.l.distributeAsBusiness(
            funds: balance / d,
            segmented: segmentedCostPerDay.l * stockpileMaxDays,
            tradeable: tradeableCostPerDay.l * stockpileMaxDays,
        )

        return budget
    }

    static func free(
        weights: __shared (
            segmented: SegmentedWeights<ElasticDemand>,
            tradeable: AggregateWeights
        ),
        balance: Int64,
        stockpileMaxDays: Int64,
        d: (l: Int64, e: Int64, x: Int64)
    ) -> Self {
        let segmentedCostPerDay: (l: Int64, e: Int64, x: Int64) = weights.segmented.total
        let tradeableCostPerDay: (l: Int64, e: Int64, x: Int64) = weights.tradeable.total
        let totalCostPerDay: (l: Int64, e: Int64) = (
            l: tradeableCostPerDay.l + segmentedCostPerDay.l,
            e: tradeableCostPerDay.e + segmentedCostPerDay.e,
        )

        /// These are the minimum theoretical balances the pop would need to purchase 100% of
        /// its needs in that tier on any particular day.
        var budget: Self = .init(
            min: (
                l: totalCostPerDay.l * d.l,
                e: totalCostPerDay.e * d.e,
            ),
            l: .init(),
            e: .init(),
            x: .init(),
            dividend: 0,
            buybacks: 0
        )

        budget.l.distributeAsConsumer(
            funds: balance / d.l,
            segmented: segmentedCostPerDay.l * stockpileMaxDays,
            tradeable: tradeableCostPerDay.l * stockpileMaxDays,
        )

        budget.e.distributeAsConsumer(
            funds: (balance - budget.min.l) / d.e,
            segmented: segmentedCostPerDay.e * stockpileMaxDays,
            tradeable: tradeableCostPerDay.e * stockpileMaxDays,
        )

        budget.x.distributeAsConsumer(
            funds: (balance - budget.min.l - budget.min.e) / d.x,
            segmented: segmentedCostPerDay.x * stockpileMaxDays,
            tradeable: tradeableCostPerDay.x * stockpileMaxDays,
        )

        return budget
    }
}
