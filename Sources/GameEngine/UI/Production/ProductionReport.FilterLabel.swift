import GameIDs

extension ProductionReport {
    enum FilterLabel: Equatable, Comparable {
        case all
        case location(String, Address)
    }
}
extension ProductionReport.FilterLabel: Identifiable {
    var id: ProductionReport.Filter {
        switch self {
        case .all: .all
        case .location(_, let address): .location(address)
        }
    }
}
extension ProductionReport.FilterLabel: LegalEntityFilterLabel {
    var name: String {
        switch self {
        case .all: "Show all"
        case .location(let name, _): name
        }
    }
}
