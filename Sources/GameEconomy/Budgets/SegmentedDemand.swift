import GameIDs

public protocol SegmentedDemand: Identifiable<Resource> {
    var id: Resource { get }
    var unitsToPurchase: Int64 { get }
    var units: Int64 { get }
    var value: Int64 { get }

    init(
        id: Resource,
        unitsToPurchase: Int64,
        units: Int64,
        value: Int64
    )
}
