import GameEconomy

struct OperatingBudget {
    let min: (l: Int64, e: Int64)

    var l: ResourceBudgetTier
    var e: ResourceBudgetTier
    var x: ResourceBudgetTier

    var clerks: Int64
    var workers: Int64
    var dividend: Int64
    var buybacks: Int64
}
extension OperatingBudget {
    init(
        workers: FactoryContext.Workforce?,
        clerks: FactoryContext.Workforce?,
        state: Factory,
        weights: __shared ResourceInputWeights,
        stockpileMaxDays: Int64,
        d: (l: Int64, e: Int64, x: Int64)
    ) {
        self.l = .init()
        self.e = .init()
        self.x = .init()

        let inelasticCostPerDay: (l: Int64, e: Int64, x: Int64) = (
            l: 0,
            e: weights.e.inelastic.total,
            x: weights.x.inelastic.total,
        )
        let tradeableCostPerDay: (l: Int64, e: Int64, x: Int64) = (
            l: 0,
            e: Int64.init(weights.e.tradeable.total.rounded(.up)),
            x: Int64.init(weights.x.tradeable.total.rounded(.up)),
        )
        let totalCostPerDay: (l: Int64, e: Int64, x: Int64) = (
            l: tradeableCostPerDay.l + inelasticCostPerDay.l,
            e: tradeableCostPerDay.e + inelasticCostPerDay.e,
            x: tradeableCostPerDay.x + inelasticCostPerDay.x,
        )

        let balance: Int64 = state.cash.balance

        let w: Int64 = workers.map { state.today.wn * Swift.min($0.limit, $0.count + 1) } ?? 0
        let c: Int64 = clerks.map { state.today.cn * Swift.min($0.limit, $0.count + 1) } ?? 0

        /// These are the minimum theoretical balances the factory would need to purchase 100%
        /// of its needs in that tier on any particular day.
        self.min = (
            l:  totalCostPerDay.l * d.l,
            e: (totalCostPerDay.e + w + c) * d.e,
        )

        self.dividend = max(0, (balance - self.min.l - self.min.e) / 3650)
        self.buybacks = max(0, (balance - self.min.l - self.min.e - self.dividend) / 365)

        self.l.distribute(
            funds: balance / d.l,
            inelastic: inelasticCostPerDay.l * stockpileMaxDays,
            tradeable: tradeableCostPerDay.l * stockpileMaxDays,
        )

        (w: self.workers, c: self.clerks) = self.e.distribute(
            funds: (balance - self.min.l) / d.e,
            inelastic: inelasticCostPerDay.e * stockpileMaxDays,
            tradeable: tradeableCostPerDay.e * stockpileMaxDays,
            w: w * stockpileMaxDays,
            c: c * stockpileMaxDays,
        ) ?? (0, 0)

        self.x.distribute(
            funds: (balance - self.min.l - self.min.e) / d.x,
            inelastic: inelasticCostPerDay.x * stockpileMaxDays,
            tradeable: tradeableCostPerDay.x * stockpileMaxDays,
        )
    }
}
