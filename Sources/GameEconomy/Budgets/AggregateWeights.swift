import GameIDs

@frozen public struct AggregateWeights<Demand> where Demand: AggregateDemand {
    public let l: Tier
    public let e: Tier
    public let x: Tier

    @inlinable init(l: Tier, e: Tier, x: Tier) {
        self.l = l
        self.e = e
        self.x = x
    }
}
extension AggregateWeights where Demand.Column: AggregateDemandColumn {
    @inlinable var valueColumns: (l: Int64, e: Int64, x: Int64) {
        (
            l: Int64.init(self.l.total.value.rounded(.up)),
            e: Int64.init(self.e.total.value.rounded(.up)),
            x: Int64.init(self.x.total.value.rounded(.up)),
        )
    }
}
extension AggregateWeights<InelasticDemand> {
    @inlinable public var value: (l: Int64, e: Int64, x: Int64) { self.valueColumns }
}
extension AggregateWeights<ElasticDemand> {
    @inlinable public var value: (l: Int64, e: Int64, x: Int64) { self.valueColumns }
}
extension AggregateWeights<InelasticDemand> {
    public static func businessNew(
        x: ResourceInputs,
        markets: borrowing WorldMarkets,
        currency: CurrencyID,
    ) -> Self {
        self.business(l: .empty, e: .empty, x: x, markets: markets, currency: currency)
    }

    public static func business(
        l: ResourceInputs,
        e: ResourceInputs,
        x: ResourceInputs,
        markets: borrowing WorldMarkets,
        currency: CurrencyID,
    ) -> Self {
        .init(
            l: .compute(demands: l.tradeable, markets: markets, currency: currency),
            e: .compute(demands: e.tradeable, markets: markets, currency: currency),
            x: .compute(demands: x.tradeable, markets: markets, currency: currency)
        )
    }
}
extension AggregateWeights<ElasticDemand> {
    public static func consumer(
        l: ResourceInputs,
        e: ResourceInputs,
        x: ResourceInputs,
        markets: borrowing WorldMarkets,
        currency: CurrencyID,
    ) -> Self {
        .init(
            l: .compute(demands: l.tradeable, markets: markets, currency: currency),
            e: .compute(demands: e.tradeable, markets: markets, currency: currency),
            x: .compute(demands: x.tradeable, markets: markets, currency: currency)
        )
    }
}
