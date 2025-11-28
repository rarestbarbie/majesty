extension CashAllocationStatement {
    enum Names {
        case building
        case factory
        case pop
    }
}
extension CashAllocationStatement.Names {
    var l: String {
        switch self {
        case .building: "Operations"
        case .factory: "Materials"
        case .pop: "Subsistence needs"
        }
    }
    var e: String {
        switch self {
        case .building: "Maintenance"
        case .factory: "Corporate expenses"
        case .pop: "Everyday needs"
        }
    }
    var x: String {
        switch self {
        case .building: "Capital expenditures"
        case .factory: "Capital expenditures"
        case .pop: "Luxury needs"
        }
    }
}
