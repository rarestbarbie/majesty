import GameIDs

extension PopType {
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
