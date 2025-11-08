extension ConditionBreakdown {
    @frozen public struct Node: Equatable, Sendable {
        public let listItem: ListItem
        public let children: [Self]

        @inlinable public init(listItem: ListItem, children: [Self] = []) {
            self.listItem = listItem
            self.children = children
        }
    }
}
