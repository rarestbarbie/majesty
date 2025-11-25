import GameIDs

extension PopType {
    var earnings: String {
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

    var jobMode: PopJobMode? {
        switch self {
        case .Livestock: nil
        case .Driver: .hourly
        case .Editor: .hourly
        case .Miner: .mining
        case .Server: nil
        case .Contractor: nil

        case .Engineer: .remote
        case .Farmer: .remote
        case .Consultant: .remote
        case .Influencer: nil

        case .Aristocrat: nil
        case .Politician: .mining
        }
    }

    func promotes(to target: Self) -> Bool {
        switch (self.stratum, target.stratum) {
        case (.Owner, .Owner): true
        case (.Clerk, .Owner): true
        case (.Clerk, .Clerk): true
        case (.Worker, .Clerk): true
        case (.Worker, .Worker): true
        default: false
        }
    }
    func demotes(to target: Self) -> Bool {
        switch (self.stratum, target.stratum) {
        case (.Owner, .Owner): true
        case (.Owner, .Clerk): true
        case (.Clerk, .Clerk): true
        case (.Clerk, .Worker): true
        case (.Worker, .Worker): true
        default: false
        }
    }
}
extension PopType {
    var descending: PopTypeDescending { .init(rawValue: self) }
}
