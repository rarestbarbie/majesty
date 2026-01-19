import D
import GameEconomy
import GameRules
import JavaScriptInterop

extension Building {
    struct Budget {
        let l: ResourceBudgetTier
        let e: ResourceBudgetTier
        let x: ResourceBudgetTier
        let liquidate: Bool
        let buybacks: Int64
        let dividend: Int64
    }
}
extension Building.Budget {
    init(
        account: Bank.Account,
        weights: __shared (
            segmented: SegmentedWeights<InelasticDemand>,
            tradeable: AggregateWeights<InelasticDemand>
        ),
        state: Building.Dimensions,
        stockpileMaxDays: Int64,
        invest: Double
    ) {
        let segmentedCostPerDay: (l: Int64, e: Int64, x: Int64) = weights.segmented.value
        let tradeableCostPerDay: (l: Int64, e: Int64, x: Int64) = weights.tradeable.value
        let totalCostPerDay: (l: Int64, e: Int64, x: Int64) = (
            l: tradeableCostPerDay.l + segmentedCostPerDay.l,
            e: tradeableCostPerDay.e + segmentedCostPerDay.e,
            x: tradeableCostPerDay.x + segmentedCostPerDay.x,
        )

        let d: CashAllocationBasis = .business
        let (basis, liquidate): (
            Int64,
            Bool
        ) = CashAllocationBasis.adjust(liquidity: account.settled, assets: state.vv)

        let bl: Int64 = stockpileMaxDays * d.l * totalCostPerDay.l
        let be: Int64 = stockpileMaxDays * d.e * totalCostPerDay.e

        let dividend: Int64 = max(0, (basis - bl - be) / (10 * d.y))
        let buybacks: Int64 = max(0, (basis - bl - be - dividend) / d.y)

        var l: ResourceBudgetTier = .init()
        var e: ResourceBudgetTier = .init()
        var x: ResourceBudgetTier = .init()

        l.distributeAsBusiness(
            funds: basis / d.l,
            segmented: segmentedCostPerDay.l * stockpileMaxDays,
            tradeable: tradeableCostPerDay.l * stockpileMaxDays,
        )
        e.distributeAsBusiness(
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

        x.distributeAsBusiness(
            funds: investment,
            segmented: segmentedCostPerDay.x * stockpileMaxDays,
            tradeable: tradeableCostPerDay.x * stockpileMaxDays,
        )

        self.init(l: l, e: e, x: x, liquidate: liquidate, buybacks: buybacks, dividend: dividend)
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
        case liquidate = "liq"

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
        js[.liquidate] = self.liquidate ? true : nil

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
            liquidate: try js[.liquidate]?.decode() ?? false,
            buybacks: try js[.buybacks].decode(),
            dividend: try js[.dividend].decode(),
        )
    }
}
#if TESTABLE
extension Building.Budget: Equatable, Hashable {}
#endif
