import GameIDs

extension PopulationReport {
    enum FilterLabel: Equatable, Comparable {
        case location(String, Address)
    }
}
extension PopulationReport.FilterLabel: Identifiable {
    var id: PopulationReport.Filter {
        switch self {
        case .location(_, let address): .location(address)
        }
    }
}
extension PopulationReport.FilterLabel: LegalEntityFilterLabel {
    var name: String {
        switch self {
        case .location(let name, _): name
        }
    }
}
