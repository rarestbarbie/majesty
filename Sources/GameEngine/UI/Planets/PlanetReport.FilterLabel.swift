import GameIDs

extension PlanetReport {
    enum FilterLabel: Equatable, Comparable {
        case planet(String, PlanetID)
    }
}
extension PlanetReport.FilterLabel: Identifiable {
    var id: PlanetID {
        switch self {
        case .planet(_, let id): id
        }
    }
}
extension PlanetReport.FilterLabel: LegalEntityFilterLabel {
    var name: String {
        switch self {
        case .planet(let name, _): name
        }
    }
}
