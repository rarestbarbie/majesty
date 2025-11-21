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
        case .Influencer: nil

        case .Aristocrat: nil
        case .Politician: .mining
        }
    }
}
extension PopType {
    var descending: PopTypeDescending { .init(rawValue: self) }
}
