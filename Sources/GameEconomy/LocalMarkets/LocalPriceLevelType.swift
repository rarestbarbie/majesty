@frozen public enum LocalPriceLevelType: Comparable, Equatable, Hashable, Sendable {
    case minimumWage
}
extension LocalPriceLevelType: CustomStringConvertible {
    @inlinable public var description: String {
        switch self {
        case .minimumWage: return "Minimum Wage"
        }
    }
}
