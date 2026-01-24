import GameIDs

extension FinancialStatement {
    enum Cost {
        case resource(id: Resource, units: Int64, value: Int64)
        case workers(value: Int64)
        case clerks(value: Int64)
    }
}
extension FinancialStatement.Cost {
    var value: Int64 {
        switch self {
        case .resource(_, _, let value): value
        case .workers(let value): value
        case .clerks(let value): value
        }
    }

    var id: FinancialStatement.CostItem {
        switch self {
        case .resource(let id, _, _): .resource(id)
        case .workers: .workers
        case .clerks: .clerks
        }
    }
}
