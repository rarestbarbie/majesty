import GameIDs

extension ProductionReport {
    enum FilterLabel: Equatable, Comparable {
        case location(String, Address)
    }
}
extension ProductionReport.FilterLabel: Identifiable {
    var id: ProductionReport.Filter {
        switch self {
        case .location(_, let address): .location(address)
        }
    }
}
extension ProductionReport.FilterLabel: LegalEntityFilterLabel {
    var name: String {
        switch self {
        case .location(let name, _): name
        }
    }
}
