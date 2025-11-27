import D
import GameEconomy
import GameRules
import JavaScriptInterop
import JavaScriptKit

extension Building {
    struct Budget {
        var l: ResourceBudgetTier
        var x: ResourceBudgetTier

        var buybacks: Int64
        var dividend: Int64
    }
}
extension Building.Budget {
    init(
        account: Bank.Account,
        state: Building.Dimensions,
        weights: __shared (
            segmented: SegmentedWeights<InelasticDemand>,
            tradeable: AggregateWeights
        ),
        stockpileMaxDays: Int64,
        d: (l: Int64, x: Int64, v: Double?)
    ) {
        self.l = .init()
        self.x = .init()

        let segmentedCostPerDay: (l: Int64, _: Int64, x: Int64) = weights.segmented.total
        let tradeableCostPerDay: (l: Int64, _: Int64, x: Int64) = weights.tradeable.total
        let totalCostPerDay: (l: Int64, x: Int64) = (
            l: tradeableCostPerDay.l + segmentedCostPerDay.l,
            x: tradeableCostPerDay.x + segmentedCostPerDay.x,
        )

        let balance: Int64 = account.settled

        let bl: Int64 = totalCostPerDay.l * d.l

        self.dividend = max(0, (balance - bl) / 3650)
        self.buybacks = max(0, (balance - bl - self.dividend) / 365)

        self.l.distributeAsBusiness(
            funds: balance / d.l,
            segmented: segmentedCostPerDay.l * stockpileMaxDays,
            tradeable: tradeableCostPerDay.l * stockpileMaxDays,
        )

        let investmentBase: Int64 = (balance - bl) / d.x
        let investment: Int64

        if  let v: Double = d.v, v < 1 {
            investment = Int64.init(Double.init(investmentBase) * v)
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
extension Building.Budget {
    enum ObjectKey: JSString, Sendable {
        case l_segmented = "ls"
        case l_tradeable = "lt"
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
