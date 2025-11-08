import GameIDs

extension PopulationReport {
    enum FilterLabel: Equatable, Comparable {
        case all
        case location(String, Address)
    }
}
extension PopulationReport.FilterLabel: Identifiable {
    var id: PopulationReport.Filter {
        switch self {
        case .all: .all
        case .location(_, let address): .location(address)
        }
    }
}
extension PopulationReport.FilterLabel: LegalEntityFilterLabel {
    var name: String {
        switch self {
        case .all: "Show all"
        case .location(let name, _): name
        }
    }
}
