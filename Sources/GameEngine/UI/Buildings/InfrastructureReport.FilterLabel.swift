import GameIDs

extension InfrastructureReport {
    enum FilterLabel: Equatable, Comparable {
        case location(String, Address)
    }
}
extension InfrastructureReport.FilterLabel: Identifiable {
    var id: InfrastructureReport.Filter {
        switch self {
        case .location(_, let address): .location(address)
        }
    }
}
extension InfrastructureReport.FilterLabel: LegalEntityFilterLabel {
    var name: String {
        switch self {
        case .location(let name, _): name
        }
    }
}
