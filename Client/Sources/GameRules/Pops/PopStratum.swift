@frozen public enum PopStratum: Comparable {
    case Ward
    case Worker
    case Clerk
    case Owner
}
extension PopStratum: CustomStringConvertible {
    @inlinable public var description: String {
        switch self {
        case .Ward: "Ward"
        case .Worker: "Worker"
        case .Clerk: "Clerk"
        case .Owner: "Owner"
        }
    }
}
extension PopStratum: LosslessStringConvertible {
    @inlinable public init?(_ string: String) {
        switch string {
        case "Ward": self = .Ward
        case "Worker": self = .Worker
        case "Clerk": self = .Clerk
        case "Owner": self = .Owner
        default: return nil
        }
    }
}
