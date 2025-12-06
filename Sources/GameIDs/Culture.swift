import Color

@frozen public struct Culture: Identifiable {
    public let id: CultureID
    public let name: String
    public let type: CultureType
    public let color: Color

    @inlinable public init(
        id: CultureID,
        name: String,
        type: CultureType,
        color: Color
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.color = color
    }
}
