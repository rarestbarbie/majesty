import D
import GameEconomy
import GameRules
import VectorCharts

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
        workers: Workforce?,
        clerks: (Workforce, FactoryMetadata.ClerkBonus)?,
        state: Factory,
        weights: __shared ResourceInputWeights,
        stockpileMaxDays: Int64,
        d: (l: Int64, e: Int64, x: Int64, v: Double?)
    ) {
        self.l = .init()
        self.e = .init()
        self.x = .init()

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
        let totalCostPerDay: (l: Int64, e: Int64, x: Int64) = (
            l: tradeableCostPerDay.l + inelasticCostPerDay.l,
            e: tradeableCostPerDay.e + inelasticCostPerDay.e,
            x: tradeableCostPerDay.x + inelasticCostPerDay.x,
        )

        let balance: Int64 = state.inventory.account.balance

        let workersTarget: Int64 = workers.map { Swift.min($0.limit, $0.count + 1) } ?? 0
        let clerksTarget: Int64 = clerks.map {
            Swift.min($0.limit, $1.optimal(for: workersTarget))
        } ?? 0

        let laborCostPerDay: (w: Int64, c: Int64) = (
            w: state.z.wn * workersTarget,
            c: state.z.cn * clerksTarget,
        )

        /// These are the minimum theoretical balances the factory would need to purchase 100%
        /// of its needs in that tier on any particular day.
        self.min = (
            l: (totalCostPerDay.l + laborCostPerDay.w + laborCostPerDay.c) * d.l,
            e: (totalCostPerDay.e) * d.e,
        )

        self.dividend = max(0, (balance - self.min.l - self.min.e) / 3650)
        self.buybacks = max(0, (balance - self.min.l - self.min.e - self.dividend) / 365)

        (w: self.workers, c: self.clerks) = self.l.distribute(
            funds: balance / d.l,
            inelastic: inelasticCostPerDay.l * stockpileMaxDays,
            tradeable: tradeableCostPerDay.l * stockpileMaxDays,
            w: laborCostPerDay.w * stockpileMaxDays,
            c: laborCostPerDay.c * stockpileMaxDays,
        ) ?? (0, 0)

        self.e.distribute(
            funds: (balance - self.min.l) / d.e,
            inelastic: inelasticCostPerDay.e * stockpileMaxDays,
            tradeable: tradeableCostPerDay.e * stockpileMaxDays,
        )

        let investmentBase: Int64 = (balance - self.min.l - self.min.e) / d.x
        let investment: Int64

        if  let v: Double = d.v, v < 1 {
            investment = Int64.init(Double.init(investmentBase) * v)
        } else {
            investment = investmentBase
        }

        self.x.distribute(
            funds: investment,
            inelastic: inelasticCostPerDay.x * stockpileMaxDays,
            tradeable: tradeableCostPerDay.x * stockpileMaxDays,
        )
    }
}
