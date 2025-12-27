import GameIDs

extension ElasticDemand {
    @frozen public struct Column {
        public let value: Double
        public let weight: Double

        @inlinable init(value: Double, weight: Double) {
            self.value = value
            self.weight = weight
        }
    }
}
extension ElasticDemand.Column: AggregateDemandColumn {
    @inlinable static var zero: Self { .init(value: 0, weight: 0) }

    @usableFromInline static func aggregate(
        demands: ArraySlice<ResourceInput>,
        markets: borrowing WorldMarkets,
        currency: CurrencyID
    ) -> Self {
        let total: (value: Double, weight: Double) = demands.reduce(into: (0, 0)) {
            let units: Int64 = $1.unitsDemanded
            let value: Double = Double.init(units) * markets.price(of: $1.id, in: currency)
            $0.value += value
            $0.weight += .sqrt(value)
        }

        return .init(value: total.value, weight: total.weight)
    }
}
