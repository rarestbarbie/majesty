import GameEconomy
import JavaScriptInterop
import JavaScriptKit

extension Pop {
    struct Budget {
        private(set) var l: ResourceBudgetTier
        private(set) var e: ResourceBudgetTier
        private(set) var x: ResourceBudgetTier
        let investment: Int64
        let dividend: Int64
        let buybacks: Int64
    }
}
extension Pop.Budget {
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

        let bl: Int64 = totalCostPerDay * d

        let dividend: Int64 = max(0, (balance - bl) / 3650)
        let buybacks: Int64 = max(0, (balance - bl - dividend) / 365)

        var budget: Self = .init(
            l: .init(),
            e: .init(),
            x: .init(),
            investment: 0,
            dividend: dividend,
            buybacks: buybacks
        )

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
        d: (l: Int64, e: Int64, x: Int64),
        investor: Bool
    ) -> Self {
        let segmentedCostPerDay: (l: Int64, e: Int64, x: Int64) = weights.segmented.total
        let tradeableCostPerDay: (l: Int64, e: Int64, x: Int64) = weights.tradeable.total
        let totalCostPerDay: (l: Int64, e: Int64) = (
            l: tradeableCostPerDay.l + segmentedCostPerDay.l,
            e: tradeableCostPerDay.e + segmentedCostPerDay.e,
        )

        /// These are the minimum theoretical balances the pop would need to purchase 100% of
        /// its needs in that tier on any particular day.
        let bl: Int64 = totalCostPerDay.l * d.l
        let be: Int64 = totalCostPerDay.e * d.e

        var budget: Self = .init(
            l: .init(),
            e: .init(),
            x: .init(),
            investment: investor ? (balance - bl - be) / d.x : 0,
            dividend: 0,
            buybacks: 0
        )

        budget.l.distributeAsConsumer(
            funds: balance / d.l,
            segmented: segmentedCostPerDay.l * stockpileMaxDays,
            tradeable: tradeableCostPerDay.l * stockpileMaxDays,
        )

        budget.e.distributeAsConsumer(
            funds: (balance - bl) / d.e,
            segmented: segmentedCostPerDay.e * stockpileMaxDays,
            tradeable: tradeableCostPerDay.e * stockpileMaxDays,
        )

        budget.x.distributeAsConsumer(
            funds: (balance - bl - be) / d.x,
            segmented: segmentedCostPerDay.x * stockpileMaxDays,
            tradeable: tradeableCostPerDay.x * stockpileMaxDays,
        )

        return budget
    }
}
extension Pop.Budget {
    enum ObjectKey: JSString, Sendable {
        case l_segmented = "ls"
        case l_tradeable = "lt"
        case e_segmented = "es"
        case e_tradeable = "et"
        case x_segmented = "xs"
        case x_tradeable = "xt"

        case investment = "i"
        case dividend = "d"
        case buybacks = "b"
    }
}
extension Pop.Budget: JavaScriptEncodable {
    func encode(to js: inout JavaScriptEncoder<ObjectKey>) {
        js[.l_segmented] = self.l.segmented
        js[.l_tradeable] = self.l.tradeable
        js[.e_segmented] = self.e.segmented
        js[.e_tradeable] = self.e.tradeable
        js[.x_segmented] = self.x.segmented
        js[.x_tradeable] = self.x.tradeable

        js[.investment] = self.investment
        js[.dividend] = self.dividend
        js[.buybacks] = self.buybacks
    }
}
extension Pop.Budget: JavaScriptDecodable {
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
            investment: try js[.investment].decode(),
            dividend: try js[.dividend].decode(),
            buybacks: try js[.buybacks].decode(),
        )
    }
}

#if TESTABLE
extension Pop.Budget: Equatable, Hashable {}
#endif
