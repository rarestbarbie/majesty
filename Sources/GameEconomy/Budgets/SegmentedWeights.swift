import GameIDs

@frozen public struct SegmentedWeights<Demand> where Demand: SegmentedDemand {
    public let l: Tier
    public let e: Tier
    public let x: Tier

    @inlinable init(l: Tier, e: Tier, x: Tier) {
        self.l = l
        self.e = e
        self.x = x
    }
}
// specialization presets
extension SegmentedWeights<InelasticDemand> {
    public static func businessNew(
        x: ResourceInputs,
        markets: LocalMarkets,
        address: Address,
    ) -> Self {
        self.business(l: .empty, e: .empty, x: x, markets: markets, address: address)
    }

    public static func business(
        l: ResourceInputs,
        e: ResourceInputs,
        x: ResourceInputs,
        markets: LocalMarkets,
        address: Address,
    ) -> Self {
        .init(
            l: .compute(demands: l.segmented, markets: markets, address: address),
            e: .compute(demands: e.segmented, markets: markets, address: address),
            x: .compute(demands: x.segmented, markets: markets, address: address)
        )
    }
}
extension SegmentedWeights<ElasticDemand> {
    public static func consumer(
        l: ResourceInputs,
        e: ResourceInputs,
        x: ResourceInputs,
        markets: LocalMarkets,
        address: Address,
    ) -> Self {
        .init(
            l: .compute(demands: l.segmented, markets: markets, address: address),
            e: .compute(demands: e.segmented, markets: markets, address: address),
            x: .compute(demands: x.segmented, markets: markets, address: address)
        )
    }
}
