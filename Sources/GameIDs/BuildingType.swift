@frozen public struct BuildingType: StaticID {
    public let rawValue: Int16
    @inlinable public init(rawValue: Int16) { self.rawValue = rawValue }
}
