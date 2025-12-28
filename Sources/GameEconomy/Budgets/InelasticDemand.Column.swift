import GameIDs

extension InelasticDemand {
    @frozen public struct Column {
        public let value: Double

        @inlinable init(value: Double) {
            self.value = value
        }
    }
}
extension InelasticDemand.Column: AggregateDemandColumn {
    @inlinable static var zero: Self { .init(value: 0) }

    @usableFromInline static func aggregate(
        demands: ArraySlice<ResourceInput>,
        markets: borrowing WorldMarkets,
        currency: CurrencyID
    ) -> Self {
        let value: Double = demands.reduce(0) {
            let units: Int64 = $1.unitsDemanded
            return $0 + Double.init(units) * markets.price(of: $1.id, in: currency)
        }
        return .init(value: value)
    }
}
