@frozen @usableFromInline struct OrderedDictionaryCollisionError<ID>: Error where ID: Sendable {
    @usableFromInline let id: ID

    @inlinable init(id: ID) {
        self.id = id
    }
}
