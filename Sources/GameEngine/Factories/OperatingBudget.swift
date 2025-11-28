import D
import GameEconomy
import GameRules
import JavaScriptInterop
import JavaScriptKit

struct OperatingBudget {
    var l: ResourceBudgetTier
    var e: ResourceBudgetTier
    var x: ResourceBudgetTier
    /// Target fulfillment for Corporate Tier, which may be less than 100 percent due to
    /// diminishing returns and high cost of Corporate inputs relative to Materials.
    let corporate: Double

    var buybacks: Int64
    var dividend: Int64
    var workers: Int64
    var clerks: Int64
}
extension OperatingBudget {
    init(
        account: Bank.Account,
        weights: __shared (
            segmented: SegmentedWeights<InelasticDemand>,
            tradeable: AggregateWeights
        ),
        state: Factory.Dimensions,
        workers: Workforce?,
        clerks: (Workforce, FactoryMetadata.ClerkBonus)?,
        stockpileMaxDays: Int64,
        invest: Double
    ) {
        self.l = .init()
        self.e = .init()
        self.x = .init()

        let segmentedCostPerDay: (l: Int64, e: Int64, x: Int64) = weights.segmented.total
        let tradeableCostPerDay: (l: Int64, e: Int64, x: Int64) = weights.tradeable.total
        let totalCostPerDay: (l: Int64, e: Int64, x: Int64) = (
            l: tradeableCostPerDay.l + segmentedCostPerDay.l,
            e: tradeableCostPerDay.e + segmentedCostPerDay.e,
            x: tradeableCostPerDay.x + segmentedCostPerDay.x,
        )

        // optimal fulfillment (fe) based on concave utility
        // Marginal Benefit = Total_Costs * 0.5 * MAX_EFFICIENCY_BONUS / sqrt(fe)
        // Equilibrium at fe = (0.5 * MAX_EFFICIENCY_BONUS * Total / Cost_E)^2
        if  totalCostPerDay.e > 0 {
            let halfBonus: Double = 0.5 * FactoryContext.efficiencyBonusFromCorporate
            /// does not include expansion costs! those are constant, and don’t scale nicely
            /// with factory utilization
            let total: Double = .init(totalCostPerDay.l + totalCostPerDay.e)
            let ratio: Double = (halfBonus * total) / Double.init(totalCostPerDay.e)
            self.corporate = min(1.0, ratio * ratio)
        } else {
            self.corporate = 1.0
        }

        let workersTarget: Int64 = workers.map { Swift.min($0.limit, $0.count + 1) } ?? 0
        let clerksTarget: Int64 = clerks.map {
            Swift.min($0.limit, $1.optimal(for: workersTarget))
        } ?? 0

        let laborCostPerDay: (w: Int64, c: Int64) = (
            w: state.wn * workersTarget,
            c: state.cn * clerksTarget,
        )

        let d: CashAllocationBasis = .business
        let v: Int64 = state.vl + state.ve
        let basis: Int64 = CashAllocationBasis.adjust(liquidity: account.settled, assets: v)

        /// These are the minimum theoretical balances the factory would need to purchase 100%
        /// of its needs in that tier on any particular day.
        let bl: Int64 = (totalCostPerDay.l + laborCostPerDay.w + laborCostPerDay.c) * d.l
        let be: Int64 = .init(
            (Double.init(totalCostPerDay.e * d.e) * self.corporate).rounded(.up)
        )

        self.dividend = max(0, (basis - bl - be) / (10 * d.y))
        self.buybacks = max(0, (basis - bl - be - self.dividend) / d.y)

        (w: self.workers, c: self.clerks) = self.l.distributeAsBusiness(
            funds: basis / d.l,
            segmented: segmentedCostPerDay.l * stockpileMaxDays,
            tradeable: tradeableCostPerDay.l * stockpileMaxDays,
            w: laborCostPerDay.w * stockpileMaxDays,
            c: laborCostPerDay.c * stockpileMaxDays,
        ) ?? (0, 0)

        self.e.distributeAsBusiness(
            funds: (basis - bl) / d.e,
            segmented: Double.init(segmentedCostPerDay.e * stockpileMaxDays) * self.corporate,
            tradeable: Double.init(tradeableCostPerDay.e * stockpileMaxDays) * self.corporate,
        )

        let investmentBase: Int64 = (basis - bl - be) / d.x
        let investment: Int64

        if  invest < 1 {
            investment = Int64.init(Double.init(investmentBase) * invest)
        } else {
            investment = investmentBase
        }

        // construction costs are inelastic
        self.x.distributeAsBusiness(
            funds: investment,
            segmented: segmentedCostPerDay.x * stockpileMaxDays,
            tradeable: tradeableCostPerDay.x * stockpileMaxDays,
        )
    }
}
extension OperatingBudget {
    enum ObjectKey: JSString, Sendable {
        case l_segmented = "ls"
        case l_tradeable = "lt"
        case e_segmented = "es"
        case e_tradeable = "et"
        case x_segmented = "xs"
        case x_tradeable = "xt"

        case corporate = "fe"
        case buybacks = "b"
        case dividend = "d"
        case workers = "w"
        case clerks = "c"
    }
}
extension OperatingBudget: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.l_segmented] = self.l.segmented
        js[.l_tradeable] = self.l.tradeable
        js[.e_segmented] = self.e.segmented
        js[.e_tradeable] = self.e.tradeable
        js[.x_segmented] = self.x.segmented
        js[.x_tradeable] = self.x.tradeable

        js[.corporate] = self.corporate
        js[.buybacks] = self.buybacks
        js[.dividend] = self.dividend
        js[.workers] = self.workers
        js[.clerks] = self.clerks
    }
}
extension OperatingBudget: JavaScriptDecodable {
    init(from js: borrowing JavaScriptDecoder<ObjectKey>) throws {
        self.init(
            l: .init(
                segmented: try js[.l_segmented].decode(),
                tradeable: try js[.l_tradeable].decode()
            ),
            e: .init(
                segmented: try js[.e_segmented].decode(),
                tradeable: try js[.e_tradeable].decode()
            ),
            x: .init(
                segmented: try js[.x_segmented].decode(),
                tradeable: try js[.x_tradeable].decode()
            ),
            corporate: try js[.corporate].decode(),
            buybacks: try js[.buybacks].decode(),
            dividend: try js[.dividend].decode(),
            workers: try js[.workers].decode(),
            clerks: try js[.clerks].decode(),
        )
    }
}
#if TESTABLE
extension OperatingBudget: Equatable, Hashable {}
#endif
