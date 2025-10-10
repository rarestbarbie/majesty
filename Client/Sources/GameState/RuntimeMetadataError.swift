@frozen @usableFromInline enum RuntimeMetadataError<ID>: Error where ID: Sendable {
    case missing(ID)
}
