import GameIDs

extension InfrastructureReport {
    enum FilterLabel: Equatable, Comparable {
        case all
        case location(String, Address)
    }
}
extension InfrastructureReport.FilterLabel: Identifiable {
    var id: InfrastructureReport.Filter {
        switch self {
        case .all: .all
        case .location(_, let address): .location(address)
        }
    }
}
extension InfrastructureReport.FilterLabel: LegalEntityFilterLabel {
    var name: String {
        switch self {
        case .all: "Show all"
        case .location(let name, _): name
        }
    }
}
