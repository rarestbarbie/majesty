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
        demands: ArraySlice<ResourceInput>,
        markets: borrowing LocalMarkets,
        address: Address,
    ) -> Self {
        .init(
            demands: demands.map {
                .init(
                    id: $0.id,
                    unitsToPurchase: $0.needed($0.unitsDemanded),
                    units: $0.unitsDemanded,
                    value: $0.unitsDemanded >< markets[$0.id / address].yesterday.ask.value
                )
            }
        )
    }

    @inlinable public var value: Int64 {
        self.demands.reduce(into: .zero) { $0 += $1.value }
    }
    @inlinable public var weight: Demand.Weight {
        self.demands.reduce(into: .zero) { $0 += $1.weight }
    }
}
