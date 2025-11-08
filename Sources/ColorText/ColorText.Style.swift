extension ColorText {
    @frozen public enum Style {
        case em
        case pos
        case neg
    }
}
extension ColorText.Style: CustomStringConvertible {
    @inlinable public var description: String {
        switch self {
        case .em: "em"
        case .pos: "ins"
        case .neg: "del"
        }
    }
}
