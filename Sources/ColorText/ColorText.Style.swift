extension ColorText {
    @frozen public enum Style {
        case em
        case pos
        case neg
    }
}
extension ColorText.Style: Identifiable {
    @inlinable public var id: String {
        switch self {
        case .em: "em"
        case .pos: "ins"
        case .neg: "del"
        }
    }
}
extension ColorText.Style: CustomStringConvertible {
    @inlinable public var description: String {
        self.id
    }
}
