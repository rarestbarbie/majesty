import GameIDs

extension PopOccupation {
    var c: String {
        // `c` is used for market refunds, so even pops that do not work independently still
        // need a name for that accounting column
        switch self {
        case .Livestock: "???"
        case .Driver: "Refunds"
        case .Editor: "Refunds"
        case .Miner: "Market earnings"
        case .Server: "Wages and tips"
        case .Contractor: "Wages and fees"
        case .Engineer: "Refunds"
        case .Farmer: "Refunds"
        case .Consultant: "Retainers"
        case .Influencer: "Royalties"
        case .Aristocrat: "Refunds"
        case .Politician: "Fundraising"
        }
    }
    var i: String {
        switch self {
        case .Livestock: "???"
        case .Driver: "Wages"
        case .Editor: "Wages"
        case .Miner: "???"
        case .Server: "???"
        case .Contractor: "???"
        case .Engineer: "Salaries"
        case .Farmer: "Salaries"
        case .Consultant: "???"
        case .Influencer: "???"
        case .Aristocrat: "Interest and dividends"
        case .Politician: "Interest and dividends"
        }
    }
    var s: String {
        // constant right now, could be customized later
        switch self.stratum {
        case .Ward: "???"
        case .Worker: "Welfare"
        case .Clerk: "Welfare"
        case .Elite: "Welfare"
        }
    }
}
extension PopOccupation {
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
