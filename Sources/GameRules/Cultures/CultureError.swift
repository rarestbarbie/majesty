import GameIDs

@frozen @usableFromInline enum CultureError: Error {
    case undefined(CultureID)
}
extension CultureError: CustomStringConvertible {
    @usableFromInline var description: String {
        switch self {
        case .undefined(let undefined):
            return "Culture with ID '\(undefined)' is not defined"
        }
    }
}
