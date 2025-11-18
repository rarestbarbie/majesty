import GameIDs

extension LocalMarket {
    @frozen public struct Fill {
        public let entity: LEI
        public let filled: Int64
        public let value: Int64
        public let memo: Memo?

        @inlinable init(
            entity: LEI,
            filled: Int64,
            value: Int64,
            memo: Memo?
        ) {
            self.entity = entity
            self.filled = filled
            self.value = value
            self.memo = memo
        }
    }
}
