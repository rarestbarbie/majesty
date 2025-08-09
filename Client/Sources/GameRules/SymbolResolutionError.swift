@frozen @usableFromInline enum SymbolResolutionError<T>: Error {
    case undefined(String)
}
