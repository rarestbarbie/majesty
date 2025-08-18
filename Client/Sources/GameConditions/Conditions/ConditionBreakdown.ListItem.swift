import ColorText

extension ConditionBreakdown {
    @frozen public struct ListItem: Equatable, Sendable {
        public let fulfilled: Bool
        public var highlight: Bool
        public let description: ColorText

        @inlinable public init(
            fulfilled: Bool,
            highlight: Bool,
            description: ColorText,
        ) {
            self.fulfilled = fulfilled
            self.highlight = highlight
            self.description = description
        }
    }
}
