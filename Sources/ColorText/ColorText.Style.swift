extension ColorText {
    @frozen public enum Style {
        case em
        case pos
        case neg
    }
}
extension ColorText.Style {
    @inlinable public var tag: String {
        switch self {
        case .em: "em"
        case .pos: "ins"
        case .neg: "del"
        }
    }
}
@available(*, deprecated, message: "Use 'tag' instead of 'description'")
extension ColorText.Style: CustomStringConvertible {
    @inlinable public var description: String { self.tag }
}
