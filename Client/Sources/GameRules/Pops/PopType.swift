import JavaScriptInterop
import JavaScriptKit

@frozen public enum PopType: Unicode.Scalar, CaseIterable,
    ConvertibleToJSValue,
    LoadableFromJSValue {
    // Slaves
    // case fauna
    // case indigent
    case Livestock = "A"

    // Workers
    case Driver = "D"
    case Editor = "E"
    case Miner = "M"
    case Server = "S"

    // Clerks
    case Engineer = "G"
    case Farmer = "F"
    // case academic
    // case bureaucrat
    // case manager
    // case soldier
    // case therapist

    // Owners
    case Capitalist = "O"
    // case influencer
}
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
extension PopType: Comparable {
    @inlinable public static func < (a: Self, b: Self) -> Bool {
        (a.stratum, a.rawValue) < (b.stratum, b.rawValue)
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
