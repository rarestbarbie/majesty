import Bijection
import JavaScriptInterop
import JavaScriptKit

@frozen public enum PopType: CaseIterable, Comparable {
    // Slaves
    // case fauna
    // case indigent
    case Livestock

    // Workers
    case Miner
    case Editor
    case Server
    case Driver

    // Clerks
    case Engineer
    case Farmer
    // case academic
    // case bureaucrat
    // case manager
    // case soldier
    // case therapist

    // Owners
    case Capitalist
    // case influencer
}
extension PopType: RawRepresentable {
    @Bijection(label: "rawValue")
    @inlinable public var rawValue: Unicode.Scalar {
        switch self {
        case .Livestock:    "A"
        case .Driver:       "D"
        case .Editor:       "E"
        case .Miner:        "M"
        case .Server:       "S"
        case .Engineer:     "G"
        case .Farmer:       "F"
        case .Capitalist:   "O"
        }
    }
}
extension PopType: ConvertibleToJSValue, LoadableFromJSValue {}
extension PopType {
    @inlinable public var stratum: PopStratum {
        switch self {
        case .Livestock:    .Ward
        case .Driver:       .Worker
        case .Editor:       .Worker
        case .Miner:        .Worker
        case .Server:       .Worker
        case .Engineer:     .Clerk
        case .Farmer:       .Clerk
        case .Capitalist:   .Owner
        }
    }
}
extension PopType {
    @inlinable public var singular: String {
        switch self {
        case .Livestock:    "Livestock"

        case .Driver:       "Driver"
        case .Editor:       "Editor"
        case .Miner:        "Miner"
        case .Server:       "Server"

        case .Engineer:     "Engineer"
        case .Farmer:       "Farmer"

        case .Capitalist:   "Capitalist"
        }
    }
    @inlinable public var plural: String {
        switch self {
        case .Livestock:    "Livestock"

        case .Driver:       "Drivers"
        case .Editor:       "Editors"
        case .Miner:        "Miners"
        case .Server:       "Servers"

        case .Engineer:     "Engineers"
        case .Farmer:       "Farmers"

        case .Capitalist:   "Capitalists"
        }
    }
}
