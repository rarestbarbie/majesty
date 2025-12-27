extension LocalMarket {
    @usableFromInline @frozen struct Shape {
        @usableFromInline let storage: Int64?

        @inlinable init(storage: Int64?) {
            self.storage = storage
        }
    }
}
