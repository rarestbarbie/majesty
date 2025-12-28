import GameEconomy
import JavaScriptInterop
import JavaScriptKit

extension Pop {
    struct Budget {
        let l: ResourceBudgetTier
        let e: ResourceBudgetTier
        let x: ResourceBudgetTier
        let investment: Int64
        let dividend: Int64
        let buybacks: Int64
    }
}
extension Pop.Budget {
    static func slave(
        account: Bank.Account,
        weights: __shared (
            segmented: SegmentedWeights<InelasticDemand>,
            tradeable: AggregateWeights<InelasticDemand>
        ),
        state: Pop.Dimensions,
        stockpileMaxDays: Int64,
    ) -> Self {
        let segmentedCostPerDay: (l: Int64, e: Int64, x: Int64) = weights.segmented.value
        let tradeableCostPerDay: (l: Int64, e: Int64, x: Int64) = weights.tradeable.value
        let totalCostPerDay: (l: Int64, e: Int64) = (
            l: tradeableCostPerDay.l + segmentedCostPerDay.l,
            e: tradeableCostPerDay.e + segmentedCostPerDay.e,
        )

        let d: CashAllocationBasis = .business
        let v: Int64 = state.vl + state.ve
        let basis: Int64 = CashAllocationBasis.adjust(liquidity: account.settled, assets: v)

        let bl: Int64 = d.l * stockpileMaxDays * totalCostPerDay.l
        let be: Int64 = d.e * stockpileMaxDays * totalCostPerDay.e

        var l: ResourceBudgetTier = .init()
        var e: ResourceBudgetTier = .init()

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

        let dividend: Int64 = max(0, (basis - bl - be) / (10 * d.y))
        let buybacks: Int64 = max(0, (basis - bl - be - dividend) / d.y)
        return .init(
            l: l,
            e: e,
            x: .init(),
            investment: 0,
            dividend: dividend,
            buybacks: buybacks
        )
    }

    static func free(
        account: Bank.Account,
        weights: __shared (
            segmented: SegmentedWeights<ElasticDemand>,
            tradeable: AggregateWeights<ElasticDemand>
        ),
        state: Pop.Dimensions,
        stockpileMaxDays: Int64,
        investor: Bool
    ) -> Self {
        let segmentedCostPerDay: (l: Int64, e: Int64, x: Int64) = weights.segmented.value
        let tradeableCostPerDay: (l: Int64, e: Int64, x: Int64) = weights.tradeable.value
        let totalCostPerDay: (l: Int64, e: Int64, x: Int64) = (
            l: tradeableCostPerDay.l + segmentedCostPerDay.l,
            e: tradeableCostPerDay.e + segmentedCostPerDay.e,
            x: tradeableCostPerDay.x + segmentedCostPerDay.x,
        )

        let d: CashAllocationBasis = .consumer
        let v: Int64 = state.vl + state.ve
        let basis: Int64 = CashAllocationBasis.adjust(liquidity: account.settled, assets: v)

        let bl: Int64 = stockpileMaxDays * d.l * totalCostPerDay.l
        let be: Int64 = stockpileMaxDays * d.e * totalCostPerDay.e

        var l: ResourceBudgetTier = .init()
        var e: ResourceBudgetTier = .init()
        var x: ResourceBudgetTier = .init()

        l.distributeAsConsumer(
            funds: basis / d.l,
            limit: totalCostPerDay.l * stockpileMaxDays,
            weights: (
                segmented: weights.segmented.l.weight,
                tradeable: weights.tradeable.l.weight
            )
        )

        e.distributeAsConsumer(
            funds: (basis - bl) / d.e,
            limit: totalCostPerDay.e * stockpileMaxDays,
            weights: (
                segmented: weights.segmented.e.weight,
                tradeable: weights.tradeable.e.weight
            )
        )

        x.distributeAsConsumer(
            funds: (basis - bl - be) / d.x,
            limit: totalCostPerDay.x * stockpileMaxDays,
            weights: (
                segmented: weights.segmented.x.weight,
                tradeable: weights.tradeable.x.weight
            )
        )

        return .init(
            l: l,
            e: e,
            x: x,
            investment: investor ? (basis - bl - be) / d.y : 0,
            dividend: 0,
            buybacks: 0
        )
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
