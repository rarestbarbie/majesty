@frozen public enum LaborMarketPolicy {
    case DEI
    case MajorityPreference
}
extension LaborMarketPolicy: CustomStringConvertible {
    @inlinable public var description: String {
        switch self {
        case .DEI: "Diversity, Equity, and Inclusion"
        case .MajorityPreference: "Majority Preference"
        }
    }
}
extension LaborMarketPolicy {
    var summary: String {
        switch self {
        case .DEI: """
            All pops have an equal chance of being hired, regardless of size
            """
        case .MajorityPreference: """
            Larger pops get more matches than smaller pops
            """
        }
    }
}
