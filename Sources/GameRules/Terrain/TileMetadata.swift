public final class TileMetadata: Sendable {
    public let ecology: EcologicalAttributes
    public let geology: GeologicalAttributes

    @inlinable init(
        ecology: EcologicalAttributes,
        geology: GeologicalAttributes
    ) {
        self.ecology = ecology
        self.geology = geology
    }
}
