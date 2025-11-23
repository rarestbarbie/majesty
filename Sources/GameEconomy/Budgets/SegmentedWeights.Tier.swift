import D
import Fraction
import OrderedCollections
import GameIDs

extension SegmentedWeights {
    @frozen public struct Tier {
        public let demands: [Demand]

        @inlinable init(demands: [Demand]) {
            self.demands = demands
        }
    }
}
extension SegmentedWeights.Tier {
    static var empty: Self { .init(demands: []) }
}
extension SegmentedWeights.Tier {
    static func compute(
        demands: OrderedDictionary<Resource, ResourceInput>,
        markets: borrowing LocalMarkets,
        address: Address,
    ) -> Self {
        .init(
            demands: demands.map {
                .init(
                    id: $0,
                    unitsToPurchase: $1.needed($1.unitsDemanded),
                    units: $1.unitsDemanded,
                    value: $1.unitsDemanded >< markets[$0 / address].yesterday.ask.value
                )
            }
        )
    }

    @inlinable public var total: Int64 {
        self.demands.reduce(into: 0) { $0 += $1.value }
    }
}
