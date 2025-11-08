@frozen @usableFromInline enum SymbolResolutionError<T>: Error {
    case undefined(String)
}
extension SymbolResolutionError: CustomStringConvertible {
    @inlinable public var description: String {
        switch self {
        case .undefined(let name):
            return "Undefined symbol: '\(name)'"
        }
    }
}
