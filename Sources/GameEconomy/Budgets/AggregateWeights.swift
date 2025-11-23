import GameIDs

@frozen public struct AggregateWeights {
    public let l: Tier
    public let e: Tier
    public let x: Tier

    @inlinable init(l: Tier, e: Tier, x: Tier) {
        self.l = l
        self.e = e
        self.x = x
    }
}
extension AggregateWeights {
    public static func businessNew(
        x: ResourceInputs,
        markets: borrowing BlocMarkets,
        currency: CurrencyID,
    ) -> Self {
        self.consumer(l: .empty, e: .empty, x: x, markets: markets, currency: currency)
    }

    public static func business(
        l: ResourceInputs,
        e: ResourceInputs,
        x: ResourceInputs,
        markets: borrowing BlocMarkets,
        currency: CurrencyID,
    ) -> Self {
        self.consumer(l: l, e: e, x: x, markets: markets, currency: currency)
    }
}
extension AggregateWeights {
    public static func consumer(
        l: ResourceInputs,
        e: ResourceInputs,
        x: ResourceInputs,
        markets: borrowing BlocMarkets,
        currency: CurrencyID,
    ) -> Self {
        .init(
            l: .compute(demands: l.segmented, markets: markets, currency: currency),
            e: .compute(demands: e.segmented, markets: markets, currency: currency),
            x: .compute(demands: x.segmented, markets: markets, currency: currency)
        )
    }
}
