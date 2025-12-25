import D
import GameEconomy
import GameRules
import JavaScriptInterop
import JavaScriptKit

extension Building {
    struct Budget {
        var l: ResourceBudgetTier
        var e: ResourceBudgetTier
        var x: ResourceBudgetTier

        var buybacks: Int64
        var dividend: Int64
    }
}
extension Building.Budget {
    init(
        account: Bank.Account,
        weights: __shared (
            segmented: SegmentedWeights<InelasticDemand>,
            tradeable: AggregateWeights
        ),
        state: Building.Dimensions,
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

        let d: CashAllocationBasis = .business
        let v: Int64 = state.vl + state.ve
        let basis: Int64 = CashAllocationBasis.adjust(liquidity: account.settled, assets: v)

        let bl: Int64 = stockpileMaxDays * d.l * totalCostPerDay.l
        let be: Int64 = stockpileMaxDays * d.e * totalCostPerDay.e

        self.dividend = max(0, (basis - bl - be) / (10 * d.y))
        self.buybacks = max(0, (basis - bl - be - self.dividend) / d.y)

        self.l.distributeAsBusiness(
            funds: basis / d.l,
            segmented: segmentedCostPerDay.l * stockpileMaxDays,
            tradeable: tradeableCostPerDay.l * stockpileMaxDays,
        )
        self.e.distributeAsBusiness(
            funds: (basis - bl) / d.e,
            segmented: segmentedCostPerDay.e * stockpileMaxDays,
            tradeable: tradeableCostPerDay.e * stockpileMaxDays,
        )

        let investmentBase: Int64 = (basis - bl - be) / d.x
        let investment: Int64

        if  invest < 1 {
            investment = Int64.init(Double.init(investmentBase) * invest)
        } else {
            investment = investmentBase
        }

        self.x.distributeAsBusiness(
            funds: investment,
            segmented: segmentedCostPerDay.x * stockpileMaxDays,
            tradeable: tradeableCostPerDay.x * stockpileMaxDays,
        )
    }
}
extension Building.Budget {
    enum ObjectKey: JSString, Sendable {
        case l_segmented = "ls"
        case l_tradeable = "lt"
        case e_segmented = "es"
        case e_tradeable = "et"
        case x_segmented = "xs"
        case x_tradeable = "xt"

        case buybacks = "b"
        case dividend = "d"
    }
}
extension Building.Budget: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.l_segmented] = self.l.segmented
        js[.l_tradeable] = self.l.tradeable
        js[.e_segmented] = self.e.segmented
        js[.e_tradeable] = self.e.tradeable
        js[.x_segmented] = self.x.segmented
        js[.x_tradeable] = self.x.tradeable

        js[.buybacks] = self.buybacks
        js[.dividend] = self.dividend
    }
}
extension Building.Budget: JavaScriptDecodable {
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
            buybacks: try js[.buybacks].decode(),
            dividend: try js[.dividend].decode(),
        )
    }
}
#if TESTABLE
extension Building.Budget: Equatable, Hashable {}
#endif
