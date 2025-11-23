import GameIDs

@frozen public struct InelasticDemand {
    public let id: Resource
    public let unitsToPurchase: Int64
    public let units: Int64
    public let value: Int64

    @inlinable public init(
        id: Resource,
        unitsToPurchase: Int64,
        units: Int64,
        value: Int64
    ) {
        self.id = id
        self.unitsToPurchase = unitsToPurchase
        self.units = units
        self.value = value
    }
}
extension InelasticDemand: SegmentedDemand {
    @inlinable public var weight: Int64 { self.value }
}
