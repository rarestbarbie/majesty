@frozen public struct OrderedDictionaryCollisionError<ID>: Error where ID: Sendable {
    @usableFromInline let id: ID

    @inlinable public init(id: ID) {
        self.id = id
    }
}
