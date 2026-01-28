import GameIDs

extension PopOccupation {
    var revenue: String {
        switch self {
        case .Livestock: "Market earnings"
        case .Driver: "Wages"
        case .Editor: "Wages"
        case .Miner: "Market earnings"
        case .Server: "Wages"
        case .Contractor: "Wages"
        case .Engineer: "Salaries"
        case .Farmer: "Salaries"
        case .Consultant: "Retainers"
        case .Influencer: "Market earnings"
        case .Aristocrat: "Fundraising"
        case .Politician: "Fundraising"
        }
    }

    var employer: PopJobType? {
        switch self {
        case .Politician: .mine
        case .Aristocrat: nil
        case .Consultant: nil
        case .Influencer: nil
        case .Engineer: .factory
        case .Farmer: .factory
        case .Driver: .factory
        case .Editor: .factory
        case .Miner: .mine
        case .Server: nil
        case .Contractor: nil
        case .Livestock: nil
        }
    }

    var mode: Mode {
        switch self {
        // politicians are miners, they mine a finite pool of regional influence
        case .Politician: .mining
        case .Aristocrat: .aristocratic

        case .Consultant: .aristocratic
        case .Influencer: .aristocratic
        case .Engineer: .remote
        case .Farmer: .remote

        case .Driver: .hourly
        case .Editor: .hourly
        case .Miner: .mining
        // yes, servers and contractors are technically livestock,
        // as they do not participate in the job market
        case .Server: .livestock
        case .Contractor: .livestock

        case .Livestock: .livestock
        }
    }

    func promotes(to target: Self) -> Bool {
        switch (self.stratum, target.stratum) {
        case (.Elite, .Elite): true
        case (.Clerk, .Elite): true
        case (.Clerk, .Clerk): true
        case (.Worker, .Clerk): true
        case (.Worker, .Worker): true
        default: false
        }
    }
    func demotes(to target: Self) -> Bool {
        switch (self.stratum, target.stratum) {
        case (.Elite, .Elite): true
        case (.Elite, .Clerk): true
        case (.Clerk, .Clerk): true
        case (.Clerk, .Worker): true
        case (.Worker, .Worker): true
        default: false
        }
    }
}
extension PopOccupation {
    var descending: PopOccupationDescending { .init(rawValue: self) }
}
