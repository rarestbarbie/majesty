@frozen public struct TileType: Equatable, Hashable, Sendable {
    public let ecology: EcologicalType
    public let geology: GeologicalType

    @inlinable public init(ecology: EcologicalType, geology: GeologicalType) {
        self.ecology = ecology
        self.geology = geology
    }
}
