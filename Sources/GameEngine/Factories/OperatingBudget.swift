import D
import GameEconomy
import GameRules
import JavaScriptInterop
import JavaScriptKit

struct OperatingBudget {
    let l: ResourceBudgetTier
    let e: ResourceBudgetTier
    let x: ResourceBudgetTier
    /// Target fulfillment for Corporate Tier, which may be less than 100 percent due to
    /// diminishing returns and high cost of Corporate inputs relative to Materials.
    let fe: Double
    let fk: Double

    let buybacks: Int64
    let dividend: Int64
    let workers: Int64
    let clerks: Int64
}
extension OperatingBudget {
    static func factory(
        account: Bank.Account,
        weights: (
            segmented: SegmentedWeights<InelasticDemand>,
            tradeable: AggregateWeights
        ),
        state: Factory.Dimensions,
        type: FactoryMetadata,
        stockpileMaxDays: Int64,
        workers: Workforce?,
        clerks: Workforce?,
        invest: Double,
        d: CashAllocationBasis,
    ) -> Self {
        var l: ResourceBudgetTier = .init()
        var e: ResourceBudgetTier = .init()
        var x: ResourceBudgetTier = .init()

        let segmentedCostPerDay: (l: Int64, e: Int64, x: Int64) = weights.segmented.total
        let tradeableCostPerDay: (l: Int64, e: Int64, x: Int64) = weights.tradeable.total
        let totalCostPerDay: (l: Int64, e: Int64, x: Int64) = (
            l: tradeableCostPerDay.l + segmentedCostPerDay.l,
            e: tradeableCostPerDay.e + segmentedCostPerDay.e,
            x: tradeableCostPerDay.x + segmentedCostPerDay.x,
        )

        let workersExpected: Int64 = workers.map { Swift.min($0.limit, $0.count + 1) } ?? 0
        let workersCostPerDay: Int64 = state.wn * workersExpected

        let clerkHorizon: Int64 = clerks.map {
            Swift.min($0.limit, type.clerkHorizon(for: workersExpected))
        } ?? 0

        let clerksCostPerDay: Int64 = state.cn * clerkHorizon

        // optimal fulfillment (fe) based on concave utility
        // Marginal Benefit = Total_Costs * 0.5 * MAX_EFFICIENCY_BONUS / sqrt(fe)
        // Equilibrium at fe = (0.5 * MAX_EFFICIENCY_BONUS * Total / Cost_E)^2
        let materials: Double = .init(totalCostPerDay.l)
        let clerksOptimal: Double
        if  clerksCostPerDay > 0 {
            let halfBonus: Double = 0.5 * FactoryContext.efficiencyBonusFromClerks
            let ratio: Double = (halfBonus * materials) / Double.init(clerksCostPerDay)
            clerksOptimal = min(1.0, ratio * ratio)
        } else {
            clerksOptimal = 1.0
        }

        let corporateOptimal: Double
        if  totalCostPerDay.e > 0 {
            /// do not include expansion costs (those are constant, and don’t scale nicely
            /// with factory utilization), or corporate costs themselves
            let halfBonus: Double = 0.5 * FactoryContext.efficiencyBonusFromCorporate
            let ratio: Double = (halfBonus * materials) / Double.init(totalCostPerDay.e)
            corporateOptimal = min(1.0, ratio * ratio)
        } else {
            corporateOptimal = 1.0
        }

        let v: Int64 = state.vl + state.ve
        let basis: Int64 = CashAllocationBasis.adjust(liquidity: account.settled, assets: v)

        /// These are the minimum theoretical balances the factory would need to fill its
        /// stockpile for that tier all the way to maximum capacity
        let bl: Int64 = stockpileMaxDays * (totalCostPerDay.l + workersCostPerDay) * d.l
        let be: Int64 = stockpileMaxDays * Int64.init(
            (
                Double.init(totalCostPerDay.e * d.e) * corporateOptimal +
                Double.init(clerksCostPerDay * d.e) * clerksOptimal
            ).rounded(.up)
        )

        let dividend: Int64 = max(0, (basis - bl - be) / (10 * d.y))
        let buybacks: Int64 = max(0, (basis - bl - be - dividend) / d.y)

        let workers: Int64 = l.distributeAsBusiness(
            funds: basis / d.l,
            segmented: segmentedCostPerDay.l * stockpileMaxDays,
            tradeable: tradeableCostPerDay.l * stockpileMaxDays,
            w: workersCostPerDay * stockpileMaxDays,
        ) ?? 0

        let clerks: Int64 = e.distributeAsBusiness(
            funds: (basis - bl) / d.e,
            segmented: Double.init(segmentedCostPerDay.e * stockpileMaxDays) * corporateOptimal,
            tradeable: Double.init(tradeableCostPerDay.e * stockpileMaxDays) * corporateOptimal,
            w: Double.init(clerksCostPerDay * stockpileMaxDays) * clerksOptimal,
        ) ?? 0

        let investmentBase: Int64 = (basis - bl - be) / d.x
        let investment: Int64

        if  invest < 1 {
            investment = Int64.init(Double.init(investmentBase) * invest)
        } else {
            investment = investmentBase
        }

        // construction costs are inelastic
        x.distributeAsBusiness(
            funds: investment,
            segmented: segmentedCostPerDay.x * stockpileMaxDays,
            tradeable: tradeableCostPerDay.x * stockpileMaxDays,
        )

        return .init(
            l: l,
            e: e,
            x: x,
            fe: corporateOptimal,
            fk: clerksOptimal,
            buybacks: buybacks,
            dividend: dividend,
            workers: workers,
            clerks: clerks
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

        case fe = "fe"
        case fk = "fk"
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

        js[.fe] = self.fe
        js[.fk] = self.fk
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
            fe: try js[.fe].decode(),
            fk: try js[.fk].decode(),
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
