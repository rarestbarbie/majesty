import Bijection

@frozen public enum PopOccupation: CaseIterable, Comparable {
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
    case Consultant
    // case bureaucrat
    // case manager
    // case soldier
    // case therapist

    // Owners
    case Aristocrat
    case Politician
}
extension PopOccupation: RawRepresentable {
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
        case .Consultant:   "X"
        case .Influencer:   "I"
        case .Aristocrat:   "O"
        case .Politician:   "P"
        }
    }
}
extension PopOccupation: CustomStringConvertible {
    @inlinable public var description: String { "\(self.rawValue)" }
}
extension PopOccupation: LosslessStringConvertible {
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
extension PopOccupation {
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
        case .Consultant:   .Clerk
        case .Influencer:   .Clerk
        case .Aristocrat:   .Elite
        case .Politician:   .Elite
        }
    }
}
extension PopOccupation {
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
        case .Consultant: "Consultant"
        case .Influencer: "Influencer"

        case .Aristocrat: "Aristocrat"
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
        case .Consultant: "Consultants"
        case .Influencer: "Influencers"

        case .Aristocrat: "Aristocrats"
        case .Politician: "Politicians"
        }
    }
}
