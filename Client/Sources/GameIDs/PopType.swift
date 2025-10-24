import Bijection

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
    case Contractor

    // Clerks
    case Engineer
    case Farmer
    case Influencer
    // case academic
    // case bureaucrat
    // case manager
    // case soldier
    // case therapist

    // Owners
    case Executive
    case Politician
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
        case .Contractor:   "C"

        case .Engineer:     "G"
        case .Farmer:       "F"
        case .Influencer:   "I"

        case .Executive:    "O"
        case .Politician:   "P"
        }
    }
}
extension PopType: CustomStringConvertible {
    @inlinable public var description: String { "\(self.rawValue)" }
}
extension PopType: LosslessStringConvertible {
    @inlinable public init?(_ string: some StringProtocol) {
        guard
        let first: Unicode.Scalar = string.unicodeScalars.first,
        string.unicodeScalars.endIndex == string.unicodeScalars.index(
            after: string.startIndex
        ) else {
            return nil
        }
        self.init(rawValue: first)
    }
}
extension PopType {
    @inlinable public var stratum: PopStratum {
        switch self {
        case .Livestock:    .Ward
        case .Driver:       .Worker
        case .Editor:       .Worker
        case .Miner:        .Worker
        case .Server:       .Worker
        case .Contractor:   .Worker
        case .Engineer:     .Clerk
        case .Farmer:       .Clerk
        case .Influencer:   .Clerk
        case .Executive:    .Owner
        case .Politician:   .Owner
        }
    }
}
extension PopType {
    @inlinable public var singular: String {
        switch self {
        case .Livestock: "Livestock"

        case .Driver: "Driver"
        case .Editor: "Editor"
        case .Miner: "Miner"
        case .Server: "Server"
        case .Contractor: "Contractor"

        case .Engineer: "Engineer"
        case .Farmer: "Farmer"
        case .Influencer: "Influencer"

        case .Executive: "Executive"
        case .Politician: "Politician"
        }
    }
    @inlinable public var plural: String {
        switch self {
        case .Livestock: "Livestock"

        case .Driver: "Drivers"
        case .Editor: "Editors"
        case .Miner: "Miners"
        case .Server: "Servers"
        case .Contractor: "Contractors"

        case .Engineer: "Engineers"
        case .Farmer: "Farmers"
        case .Influencer: "Influencers"

        case .Executive: "Executives"
        case .Politician: "Politicians"
        }
    }
}
