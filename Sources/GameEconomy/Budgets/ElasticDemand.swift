import GameIDs
import RealModule

@frozen public struct ElasticDemand: AggregateDemand, SegmentedDemand {
    public let id: Resource
    public let unitsToPurchase: Int64
    public let units: Int64
    public let value: Int64

    public let weight: Double

    @inlinable public init(
        id: Resource,
        unitsToPurchase: Int64,
        units: Int64,
        value: Int64
    ) {
        /// perhaps this can be cached in the market
        let weight: Double = .sqrt(Double.init(value))
        self.id = id
        self.unitsToPurchase = unitsToPurchase
        self.units = units
        self.value = value
        self.weight = weight
    }
}
